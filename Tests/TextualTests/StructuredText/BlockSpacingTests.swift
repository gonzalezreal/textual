#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct BlockSpacingTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      private struct PlainParagraphStyle: ParagraphStyle {
        func makeBody(configuration: Configuration) -> some View {
          configuration.label
        }
      }

      @Test func blocksWithoutBlockSpacingUseViewSpacing() {
        let view = StructuredText(
          markdown: """
            The sky above the port was the color of television, tuned to a dead channel.

            It was a bright cold day in April, and the clocks were striking thirteen.

            > A quote between paragraphs.

            Call me Ishmael.
            """
        )
        .textual.paragraphStyle(PlainParagraphStyle())
        .background(Color.guide)
        .padding(.horizontal)
        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }
#endif
