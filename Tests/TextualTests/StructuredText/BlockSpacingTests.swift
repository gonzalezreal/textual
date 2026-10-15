#if os(iOS) && !targetEnvironment(macCatalyst)
  import SnapshotTesting
  import SwiftUI
  import Testing

  import Textual

  extension StructuredText {
    @MainActor
    struct BlockSpacingTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      // Lists and block quotes take their spacing from the blocks inside them
      @Test func containerBlocksBetweenParagraphs() {
        let view = StructuredText(
          markdown: """
            The sky above the port was the color of television, tuned to a dead channel.

            - Systems
            - FFF units

            It was a bright cold day in April, and the clocks were striking thirteen.

            > Well, art is art, isn't it? Still, on the other hand, water is water!

            The sky above the port was the color of television, tuned to a dead channel.

            1. First
            2. Second
            """
        )
        .background(Color.guide)
        .padding(.horizontal)
        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }

      @Test func spacingSetInsideAContainerApplies() {
        let atRoot = height(paragraphStyle: SpacingAtRootStyle())
        let insideContainer = height(paragraphStyle: SpacingInsideContainerStyle())
        let withoutSpacing = height(paragraphStyle: WithoutSpacingStyle())

        #expect(insideContainer == atRoot)
        #expect(atRoot > withoutSpacing)
      }

      private func height(paragraphStyle: some StructuredText.ParagraphStyle) -> CGFloat {
        let window = TestWindow(
          StructuredText(
            markdown: """
              The sky above the port was the color of television, tuned to a dead channel.

              It was a bright cold day in April, and the clocks were striking thirteen.
              """
          )
          .textual.paragraphStyle(paragraphStyle)
        )
        return window.rootViewController.sizeThatFits(
          in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude)
        )
        .height
      }
    }
  }

  private struct SpacingAtRootStyle: StructuredText.ParagraphStyle {
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .textual.blockSpacing(.init(top: 24))
    }
  }

  private struct SpacingInsideContainerStyle: StructuredText.ParagraphStyle {
    func makeBody(configuration: Configuration) -> some View {
      VStack(alignment: .leading) {
        configuration.label
          .textual.blockSpacing(.init(top: 24))
      }
    }
  }

  private struct WithoutSpacingStyle: StructuredText.ParagraphStyle {
    func makeBody(configuration: Configuration) -> some View {
      configuration.label
    }
  }
#endif
