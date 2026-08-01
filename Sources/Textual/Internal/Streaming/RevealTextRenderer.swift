import SwiftUI

// MARK: - Overview
//
// RevealTextRenderer paints a Text.Layout with a subtle per-glyph-cluster opacity + blur fade,
// used while a TextFragment is actively streaming (see TextFragment.swift and RevealClock.swift,
// which drive `revealedGlyphCount` from a checkpoint-and-elapsed-time formula rather than
// SwiftUI's `withAnimation` interpolation).
//
// Every line/run/slice in the layout is walked as one continuous glyph-index sequence — there's
// no special-casing at line boundaries, so the fade continues seamlessly across a wrapped line.
// Attachment placeholders (see AttachmentAttribute.swift) render as a single run slice, so
// they're already revealed as an atomic unit with no extra handling needed.
//
// There is no `flattenedRunSlices` helper — it isn't part of the SDK (every known reference
// implementation of this pattern reimplements the Line -> Run -> RunSlice flattening themselves);
// the nested loop below is the equivalent, without an intermediate allocation.
//
// `progress` is deliberately a pure function of only `clusterStart` (fixed once a glyph is
// assigned an index), `revealedGlyphCount`, and `fadeWindow` — never of the content's total
// length. An earlier version clamped a glyph's fade window to the total so short content could
// still reach full opacity, but the total grows as more content streams in, and that clamp's
// denominator grew retroactively for clusters whose `clusterStart` never moved — an
// already-fully-revealed glyph could silently drop back below full opacity the moment more
// content arrived. Keeping "short content should still reach full opacity" as RevealState's
// concern (padding the reveal clock's ceiling past the target — see RevealState.swift) instead
// keeps this formula monotonic: once a glyph reaches full opacity, it can never regress.

struct RevealTextRenderer: TextRenderer, Animatable {
  /// The number of glyphs that should be fully or partially visible. Supplied as an
  /// already-computed instantaneous value by `TextFragment`'s `TimelineView`-driven clock.
  var revealedGlyphCount: Double

  let configuration: RevealAnimation

  var animatableData: Double {
    get { revealedGlyphCount }
    set { revealedGlyphCount = newValue }
  }

  func draw(layout: Text.Layout, in context: inout GraphicsContext) {
    var glyphIndex = 0

    for line in layout {
      for run in line {
        for slice in run {
          defer { glyphIndex += 1 }

          let clusterStart = Double((glyphIndex / configuration.clusterSize) * configuration.clusterSize)
          let progress = Self.progress(
            clusterStart: clusterStart,
            revealedGlyphCount: revealedGlyphCount,
            fadeWindow: configuration.fadeWindow
          )

          if progress <= 0 {
            // Not yet revealed — skip drawing entirely.
            continue
          }

          if progress >= 1 {
            // Settled — cheap normal draw, no filter/opacity overhead.
            context.draw(slice)
            continue
          }

          // No translation/slide anywhere either — pure opacity + blur reads best.
          var sliceContext = context
          sliceContext.opacity = progress
          sliceContext.addFilter(.blur(radius: configuration.blurRadius * (1 - progress)))
          sliceContext.draw(slice)
        }
      }
    }
  }

  /// The fade progress (0...1) for a glyph cluster starting at `clusterStart`, given how far the
  /// reveal has advanced and the configured fade window. Monotonically non-decreasing in
  /// `revealedGlyphCount` for a fixed `clusterStart` — see the file overview for why that matters.
  static func progress(
    clusterStart: Double,
    revealedGlyphCount: Double,
    fadeWindow: Double
  ) -> Double {
    let rawProgress = (revealedGlyphCount - clusterStart) / max(fadeWindow, 1)
    return smoothstep(clamp(rawProgress, to: 0...1))
  }
}

private func smoothstep(_ x: Double) -> Double {
  x * x * (3 - 2 * x)
}

private func clamp(_ x: Double, to range: ClosedRange<Double>) -> Double {
  min(range.upperBound, max(range.lowerBound, x))
}

#Preview("Reveal Progress") {
  @Previewable @State var revealedGlyphCount: Double = 20

  VStack(alignment: .leading, spacing: 16) {
    Text(
      "The quick brown fox jumps over the lazy dog, revealing itself one small cluster of glyphs at a time."
    )
    .font(.title3)
    .textRenderer(RevealTextRenderer(revealedGlyphCount: revealedGlyphCount, configuration: .default))

    Slider(value: $revealedGlyphCount, in: 0...110)
  }
  .padding()
}
