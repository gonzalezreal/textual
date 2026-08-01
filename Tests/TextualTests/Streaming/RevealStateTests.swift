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

  @Test func revealAdvancesOverTimeAndClampsToTarget() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 10
    configuration.maxBacklogDuration = 10  // large enough that the backlog cap doesn't kick in
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
    var state = RevealState()
    let now = Date()

    state.apply(.append(newCount: 100), configuration: configuration, now: now)
    state.snapToFull()

    #expect(state.currentGlyphCount(at: now) == 100)
    #expect(state.isCaughtUp)
  }
}
