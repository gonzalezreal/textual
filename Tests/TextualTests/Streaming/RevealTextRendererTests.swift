import Testing

@testable import Textual

struct RevealTextRendererProgressTests {
  @Test func progressReachesFullOpacityOnceCaughtUpEvenForShortContent() {
    // Content shorter than fadeWindow: once revealedGlyphCount reaches the total, every glyph —
    // including the very first cluster — must reach full progress. This was the bug behind the
    // table-cell "ghosting" issue: a wide fadeWindow relative to short content left early
    // clusters permanently stuck below full opacity, since revealedGlyphCount is capped at the
    // content's own total and could never satisfy an unclamped window.
    let progress = RevealTextRenderer.progress(
      clusterStart: 0,
      revealedGlyphCount: 10,
      fadeWindow: 80,
      totalGlyphCount: 10
    )

    #expect(progress == 1)
  }

  @Test func progressClampsTrailingClusterToReachFullOpacityAtTotal() {
    // The trailing cluster of a 100-glyph fragment with a wide fadeWindow: without the fix,
    // reaching progress 1 would require revealedGlyphCount to exceed totalGlyphCount, which
    // never happens since it's capped at the total.
    let progress = RevealTextRenderer.progress(
      clusterStart: 96,
      revealedGlyphCount: 100,
      fadeWindow: 80,
      totalGlyphCount: 100
    )

    #expect(progress == 1)
  }

  @Test func progressStaysZeroBeforeReveal() {
    let progress = RevealTextRenderer.progress(
      clusterStart: 20,
      revealedGlyphCount: 5,
      fadeWindow: 80,
      totalGlyphCount: 100
    )

    #expect(progress == 0)
  }

  @Test func progressUnclampedWellWithinLongContent() {
    // Far from the tail, the window shouldn't be clamped at all — behavior should match the
    // plain (unclamped) formula.
    let progress = RevealTextRenderer.progress(
      clusterStart: 0,
      revealedGlyphCount: 40,
      fadeWindow: 80,
      totalGlyphCount: 1_000
    )
    let raw = 40.0 / 80.0
    let expected = raw * raw * (3 - 2 * raw)

    #expect(abs(progress - expected) < 0.0001)
  }
}

#if os(macOS)
  import SwiftUI

  @MainActor
  struct RevealTextRendererRenderingTests {
    @Test func rendersAtVariousProgressWithoutCrashing() {
      let text = "The quick brown fox jumps over the lazy dog, one glyph cluster at a time."

      for revealedGlyphCount: Double in [0, 3, 10, 25, 60, 1_000] {
        let renderer = ImageRenderer(
          content: Text(text)
            .textRenderer(
              RevealTextRenderer(
                revealedGlyphCount: revealedGlyphCount,
                totalGlyphCount: Double(text.count),
                configuration: .default
              )
            )
            .frame(width: 320)
            .fixedSize(horizontal: false, vertical: true)
        )
        renderer.proposedSize = .init(width: 320, height: 200)

        #expect(renderer.nsImage != nil)
      }
    }

    @Test func rendersWithCustomConfigurationWithoutCrashing() {
      var configuration = RevealAnimation.default
      configuration.blurRadius = 6
      configuration.clusterSize = 4
      configuration.fadeWindow = 5

      let text = "Hello, streaming world!"
      let renderer = ImageRenderer(
        content: Text(text)
          .textRenderer(
            RevealTextRenderer(
              revealedGlyphCount: 6,
              totalGlyphCount: Double(text.count),
              configuration: configuration
            )
          )
          .frame(width: 320)
          .fixedSize(horizontal: false, vertical: true)
      )
      renderer.proposedSize = .init(width: 320, height: 100)

      #expect(renderer.nsImage != nil)
    }

    @Test func rendersShortContentWithWideFadeWindowWithoutCrashing() {
      // Regression coverage for the ghosting bug: short content with a fadeWindow wider than
      // its own length should still render (and, per the progress tests above, reach full
      // opacity) once caught up.
      var configuration = RevealAnimation.default
      configuration.fadeWindow = 80

      let text = "Word fade"
      let renderer = ImageRenderer(
        content: Text(text)
          .textRenderer(
            RevealTextRenderer(
              revealedGlyphCount: Double(text.count),
              totalGlyphCount: Double(text.count),
              configuration: configuration
            )
          )
          .frame(width: 320)
          .fixedSize(horizontal: false, vertical: true)
      )
      renderer.proposedSize = .init(width: 320, height: 100)

      #expect(renderer.nsImage != nil)
    }
  }
#endif
