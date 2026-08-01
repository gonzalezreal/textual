import Foundation

// MARK: - Overview
//
// RevealClock computes the reveal-progress value shown at any instant, as a pure function of an
// "anchor" checkpoint (a glyph count and the rate to advance from it) and elapsed wall-clock time.
// TextFragment re-anchors on every content change (a new streaming burst) and re-anchors again
// whenever streaming ends, so the anchor's rate always reflects the current situation:
//
// - Normally, a fixed nominal rate (`RevealAnimation.glyphsPerSecond`) — a comfortable, constant
//   typing pace, decoupled from how choppy the underlying delivery is.
// - If backlog (arrived-but-not-yet-revealed content) exceeds `RevealAnimation.maxBacklogDuration`
//   worth of glyphs at the nominal rate, a boosted rate that clears the backlog within that
//   budget — so the visible reveal is never more than a bounded amount of time behind reality.
// - The instant streaming ends, an aggressive rate that clears any remaining backlog within
//   `RevealAnimation.streamEndCatchUpDuration` — because once the source is done, there's no
//   more content to "reveal as it arrives," so continuing at the leisurely nominal pace would
//   only add artificial delay to something the user could otherwise read right now.
//
// This makes the reveal a smoothing/pacing layer, never a gate: it can make text feel like it's
// arriving at a comfortable pace, but it can never make the complete response take meaningfully
// longer to fully appear than the underlying data took to arrive.

enum RevealClock {
  /// The reveal rate, in glyphs per second, to use for the upcoming catch-up window.
  ///
  /// Call this once per checkpoint (each time content changes, or streaming ends) — not every
  /// frame — and hold the result alongside the anchor until the next checkpoint.
  static func effectiveRate(
    backlogGlyphs: Double,
    isStreamEnding: Bool,
    configuration: RevealAnimation
  ) -> Double {
    guard backlogGlyphs > 0 else {
      return configuration.glyphsPerSecond
    }

    if isStreamEnding {
      return backlogGlyphs / configuration.streamEndCatchUpDuration
    }

    let backlogDuration = backlogGlyphs / configuration.glyphsPerSecond
    guard backlogDuration > configuration.maxBacklogDuration else {
      return configuration.glyphsPerSecond
    }

    return backlogGlyphs / configuration.maxBacklogDuration
  }

  /// The revealed glyph count at `elapsed` seconds after a checkpoint, given the checkpoint's
  /// glyph count and rate, clamped to `target` (the reveal never overshoots what's actually
  /// arrived).
  static func revealedGlyphCount(
    anchorGlyphCount: Double,
    target: Double,
    rate: Double,
    elapsed: TimeInterval
  ) -> Double {
    min(target, anchorGlyphCount + rate * max(0, elapsed))
  }
}
