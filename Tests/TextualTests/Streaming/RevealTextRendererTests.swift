import Testing

@testable import Textual

struct RevealTextRendererProgressTests {
  @Test func progressStaysZeroBeforeReveal() {
    let progress = RevealTextRenderer.progress(
      clusterStart: 20,
      revealedGlyphCount: 5,
      fadeWindow: 80
    )

    #expect(progress == 0)
  }

  @Test func progressReachesFullOpacityOnceRevealedCountClearsTheWindow() {
    let progress = RevealTextRenderer.progress(
      clusterStart: 0,
      revealedGlyphCount: 80,
      fadeWindow: 80
    )

    #expect(progress == 1)
  }

  @Test func progressUnaffectedByLaterClusters() {
    // Far from the tail, the window shouldn't be affected by anything else — matches the plain
    // formula directly.
    let progress = RevealTextRenderer.progress(
      clusterStart: 0,
      revealedGlyphCount: 40,
      fadeWindow: 80
    )
    let raw = 40.0 / 80.0
    let expected = raw * raw * (3 - 2 * raw)

    #expect(abs(progress - expected) < 0.0001)
  }

  @Test func progressIsMonotonicAsRevealedGlyphCountIncreases() {
    // For a fixed clusterStart, progress must never decrease as revealedGlyphCount grows — this
    // is the invariant that prevents already-revealed text from "blinking" back to a lower
    // opacity. It must hold regardless of anything else (like a growing content length) changing
    // elsewhere, since this function doesn't take a content length at all.
    var previous = 0.0
    var revealedGlyphCount = 0.0
    while revealedGlyphCount <= 120 {
      let progress = RevealTextRenderer.progress(
        clusterStart: 40, revealedGlyphCount: revealedGlyphCount, fadeWindow: 80
      )
      #expect(progress >= previous)
      previous = progress
      revealedGlyphCount += 1
    }
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
              RevealTextRenderer(revealedGlyphCount: revealedGlyphCount, configuration: .default)
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

      let renderer = ImageRenderer(
        content: Text("Hello, streaming world!")
          .textRenderer(RevealTextRenderer(revealedGlyphCount: 6, configuration: configuration))
          .frame(width: 320)
          .fixedSize(horizontal: false, vertical: true)
      )
      renderer.proposedSize = .init(width: 320, height: 100)

      #expect(renderer.nsImage != nil)
    }
  }
#endif
