import Foundation

// MARK: - Overview
//
// RevealState is the per-TextFragment state machine that ties RevealDiff (classifying how
// content changed) and RevealClock (the pure rate/position math) together. It holds a checkpoint
// — a glyph count, the date it was set, and the rate to advance from it — plus the current
// target glyph count. `currentGlyphCount(at:)` is a pure function of that checkpoint and how much
// time has elapsed, so no per-frame mutation is needed: TextFragment's TimelineView just calls it
// with the current date each tick.

struct RevealState: Equatable {
  private(set) var anchorGlyphCount: Double = 0
  private(set) var anchorDate: Date = .distantPast
  private(set) var rate: Double = 0
  private(set) var targetGlyphCount: Int = 0

  /// The revealed glyph count at `date`, given the current checkpoint.
  func currentGlyphCount(at date: Date) -> Double {
    RevealClock.revealedGlyphCount(
      anchorGlyphCount: anchorGlyphCount,
      target: Double(targetGlyphCount),
      rate: rate,
      elapsed: date.timeIntervalSince(anchorDate)
    )
  }

  /// Whether the checkpoint has already fully drained toward the target — i.e. no ticking is
  /// needed right now.
  var isCaughtUp: Bool {
    anchorGlyphCount >= Double(targetGlyphCount)
  }

  /// Updates state in response to a content change, given how the content changed relative to
  /// what was previously shown.
  mutating func apply(
    _ change: RevealDiff.Change,
    configuration: RevealAnimation,
    now: Date
  ) {
    switch change {
    case .unchanged:
      return

    case .append(let newCount), .reflowAheadOfFrontier(let newCount):
      recheckpoint(target: newCount, isStreamEnding: false, configuration: configuration, now: now)

    case .reflowBehindFrontier(let safeCount, let newCount):
      // Never animate a re-hide: jump forward (never back) to at least `safeCount` instantly,
      // then resume normal reveal toward `newCount`.
      let current = currentGlyphCount(at: now)
      anchorGlyphCount = max(current, Double(safeCount))
      anchorDate = now
      recheckpoint(target: newCount, isStreamEnding: false, configuration: configuration, now: now)
    }
  }

  /// Re-anchors toward the same target using the aggressive stream-end catch-up rate, so any
  /// remaining backlog resolves almost immediately rather than continuing at the nominal pace.
  /// Call when streaming ends — never when reveal is merely being turned off (see `snapToFull`).
  mutating func fastFinish(configuration: RevealAnimation, now: Date) {
    recheckpoint(
      target: targetGlyphCount, isStreamEnding: true, configuration: configuration, now: now
    )
  }

  /// Snaps immediately to full length with no animated catch-up at all. Use when reveal stops
  /// for a reason unrelated to the stream ending (Reduce Motion, `isEnabled == false`, or this
  /// fragment no longer being the active one) — see `fastFinish` for the stream-ending case.
  mutating func snapToFull() {
    anchorGlyphCount = Double(targetGlyphCount)
    anchorDate = .distantPast
    rate = 0
  }

  private mutating func recheckpoint(
    target: Int, isStreamEnding: Bool, configuration: RevealAnimation, now: Date
  ) {
    let current = currentGlyphCount(at: now)
    let backlog = max(0, Double(target) - current)

    rate = RevealClock.effectiveRate(
      backlogGlyphs: backlog, isStreamEnding: isStreamEnding, configuration: configuration
    )
    anchorGlyphCount = current
    anchorDate = now
    targetGlyphCount = target
  }
}
