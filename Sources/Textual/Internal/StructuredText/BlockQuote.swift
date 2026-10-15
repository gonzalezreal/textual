import SwiftUI

extension StructuredText {
  struct BlockQuote: View {
    @Environment(\.blockQuoteStyle) private var blockQuoteStyle

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring

    init(intent: PresentationIntent.IntentType?, content: AttributedSubstring) {
      self.intent = intent
      self.content = content
    }

    var body: some View {
      Group(subviews: BlockContent(parent: intent, content: content)) { label in
        let configuration = BlockStyleConfiguration(
          label: .init(label),
          indentationLevel: indentationLevel
        )
        let resolvedStyle = blockQuoteStyle.resolve(configuration: configuration)

        AnyView(resolvedStyle)
          // The style can place the label inside a container, which hides its spacing
          .containerValue(\.nestedBlockSpacing, label.blockSpacing)
      }
    }

    private var indentationLevel: Int {
      content.runs.first?.presentationIntent?.indentationLevel ?? 0
    }
  }
}
