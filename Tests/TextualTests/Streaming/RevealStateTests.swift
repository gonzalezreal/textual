import Foundation
import Testing

@testable import Textual

struct RevealStateTests {
  @Test func freshStateHasNothingToReveal() {
    let state = RevealState()

    #expect(state.targetGlyphCount == 0)
    #expect(state.isCaughtUp)
  }

  @Test func firstAppendRevealsFromZero() {
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 30), configuration: .default, now: now)

    #expect(state.targetGlyphCount == 30)
    #expect(state.currentGlyphCount(at: now) == 0)
    #expect(!state.isCaughtUp)
  }

  @Test func revealAdvancesOverTimeAndClampsToCeiling() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 10
    configuration.maxBacklogDuration = 10  // large enough that the backlog cap doesn't kick in
    configuration.fadeWindow = 0  // isolate plain clamping from the ceiling padding below
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 30), configuration: configuration, now: now)

    #expect(state.currentGlyphCount(at: now.addingTimeInterval(1)) == 10)
    #expect(state.currentGlyphCount(at: now.addingTimeInterval(10)) == 30)  // clamped
  }

  @Test func burstMidRevealCheckpointsFromCurrentPositionNotOldTarget() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 10
    configuration.maxBacklogDuration = 10  // large enough that the backlog cap doesn't kick in
    var state = RevealState()
    let start = Date()

    state.apply(.append(newCount: 20), configuration: configuration, now: start)
    let midway = start.addingTimeInterval(1)  // revealed 10 of 20 so far

    // A new burst arrives before the first one finished revealing.
    state.apply(.append(newCount: 50), configuration: configuration, now: midway)

    // The new checkpoint should start from wherever we currently are (10), not jump or reset.
    #expect(state.currentGlyphCount(at: midway) == 10)
    #expect(state.targetGlyphCount == 50)
  }

  @Test func unchangedChangeIsANoOp() {
    var configuration = RevealAnimation.default
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 30), configuration: configuration, now: now)
    let before = state

    state.apply(.unchanged, configuration: configuration, now: now.addingTimeInterval(5))

    #expect(state == before)
  }

  @Test func reflowBehindFrontierNeverUnreveals() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 100  // fast enough to be fully caught up quickly
    configuration.fadeWindow = 0  // isolate from the ceiling padding
    var state = RevealState()
    let start = Date()

    state.apply(.append(newCount: 20), configuration: configuration, now: start)
    let later = start.addingTimeInterval(1)  // fully caught up to 20 by now
    #expect(state.currentGlyphCount(at: later) == 20)

    // Reparse altered text the user already saw (revealed through 20), but the new safe prefix
    // only covers the first 12 characters.
    state.apply(
      .reflowBehindFrontier(safeCount: 12, newCount: 25), configuration: configuration, now: later
    )

    // Must never drop below what was already shown.
    #expect(state.currentGlyphCount(at: later) >= 20)
    #expect(state.targetGlyphCount == 25)
  }

  @Test func fastFinishResolvesRemainingBacklogQuickly() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 5
    configuration.streamEndCatchUpDuration = 0.1
    configuration.fadeWindow = 0  // isolate from the ceiling padding
    var state = RevealState()
    let start = Date()

    state.apply(.append(newCount: 100), configuration: configuration, now: start)
    // At the nominal rate this would take 20s; fast-finish should resolve it in ~0.1s instead.
    state.fastFinish(configuration: configuration, now: start)

    #expect(state.currentGlyphCount(at: start.addingTimeInterval(0.1)) == 100)
  }

  @Test func snapToFullHasNoAnimatedCatchUp() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 1  // deliberately slow
    configuration.fadeWindow = 0  // isolate from the ceiling padding
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 100), configuration: configuration, now: now)
    state.snapToFull()

    #expect(state.currentGlyphCount(at: now) == 100)
    #expect(state.isCaughtUp)
  }

  // MARK: - revealCeiling (fadeWindow padding)

  @Test func revealCeilingPadsPastTargetByFadeWindow() {
    var configuration = RevealAnimation.default
    configuration.fadeWindow = 80
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 6), configuration: configuration, now: now)

    #expect(state.revealCeiling == 86)
  }

  @Test func isCaughtUpReflectsTheCeilingNotJustTheRawTarget() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 1_000  // fast enough to reach the ceiling within ~1s
    configuration.fadeWindow = 80
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 6), configuration: configuration, now: now)
    #expect(state.revealCeiling == 86)
    #expect(!state.isCaughtUp)  // anchor is still 0 right at the checkpoint

    // A later checkpoint (even for the same target) re-anchors from the live interpolated
    // value — by now, at 1000 glyphs/sec, that value has clamped at the ceiling (86), not just
    // the raw target (6).
    let later = now.addingTimeInterval(1)
    state.apply(.append(newCount: 6), configuration: configuration, now: later)

    #expect(state.isCaughtUp)
  }

  // MARK: - Regression: no "blinking" when content grows

  @Test func currentGlyphCountNeverDecreasesWhenMoreContentArrives() {
    // The bug this guards against: an early glyph cluster that had already reached full opacity
    // under a small target must not become "unreached" again once more content extends the
    // target. Concretely: currentGlyphCount at a fixed instant must never decrease across a
    // recheckpoint, regardless of how the target changes.
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 1_000  // reach the ceiling almost immediately
    configuration.fadeWindow = 80
    var state = RevealState()
    let start = Date()

    state.apply(.append(newCount: 1), configuration: configuration, now: start)
    let caughtUpToOne = start.addingTimeInterval(0.1)
    let beforeGrowth = state.currentGlyphCount(at: caughtUpToOne)
    #expect(beforeGrowth >= 1)  // caught up to the short content's own length

    // More content arrives, extending the target well past the fade window.
    state.apply(.append(newCount: 6), configuration: configuration, now: caughtUpToOne)
    let afterGrowth = state.currentGlyphCount(at: caughtUpToOne)

    #expect(afterGrowth >= beforeGrowth)
  }

  @Test func earlyClusterProgressNeverRegressesWhenContentGrows() {
    // End-to-end version of the same regression, through the actual renderer formula: the first
    // glyph cluster (clusterStart 0) reaches full opacity while content is short, then more
    // content arrives — its progress, recomputed from the new currentGlyphCount, must still be 1.
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 1_000
    configuration.fadeWindow = 80
    var state = RevealState()
    let start = Date()

    state.apply(.append(newCount: 1), configuration: configuration, now: start)
    let caughtUpToOne = start.addingTimeInterval(0.1)
    let revealedBefore = state.currentGlyphCount(at: caughtUpToOne)
    let progressBefore = RevealTextRenderer.progress(
      clusterStart: 0, revealedGlyphCount: revealedBefore, fadeWindow: configuration.fadeWindow
    )
    #expect(progressBefore == 1)

    state.apply(.append(newCount: 6), configuration: configuration, now: caughtUpToOne)
    let revealedAfter = state.currentGlyphCount(at: caughtUpToOne)
    let progressAfter = RevealTextRenderer.progress(
      clusterStart: 0, revealedGlyphCount: revealedAfter, fadeWindow: configuration.fadeWindow
    )

    #expect(progressAfter == 1)
  }
}
