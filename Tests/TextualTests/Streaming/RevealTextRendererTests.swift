#if os(macOS)
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct RevealTextRendererTests {
    @Test func rendersAtVariousProgressWithoutCrashing() {
      for revealedGlyphCount: Double in [0, 3, 10, 25, 60, 1_000] {
        let renderer = ImageRenderer(
          content: Text(
            "The quick brown fox jumps over the lazy dog, one glyph cluster at a time."
          )
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
