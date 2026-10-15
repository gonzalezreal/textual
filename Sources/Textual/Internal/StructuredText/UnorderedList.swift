import SwiftUI

extension StructuredText {
  struct UnorderedList: View {
    @Environment(\.listItemSpacing) private var listItemSpacing
    @Environment(\.textEnvironment) private var textEnvironment

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring

    init(intent: PresentationIntent.IntentType?, content: AttributedSubstring) {
      self.intent = intent
      self.content = content
    }

    var body: some View {
      let runs = content.blockRuns(parent: intent)

      BlockVStack {
        ForEach(runs.indices, id: \.self) { index in
          let run = runs[index]

          UnorderedListItem(
            intent: run.intent,
            content: content[run.range]
          )
        }
      }
      .environment(\.resolvedListItemSpacing, listItemSpacing.resolve(in: textEnvironment))
      .environment(\.listItemSpacingEnabled, true)
    }
  }
}

extension StructuredText {
  fileprivate struct UnorderedListItem: View {
    @Environment(\.listItemStyle) private var listItemStyle
    @Environment(\.unorderedListMarker) private var unorderedListMarker

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring

    init(
      intent: PresentationIntent.IntentType?,
      content: AttributedSubstring
    ) {
      self.intent = intent
      self.content = content
    }

    var body: some View {
      Group(subviews: BlockContent(parent: intent, content: content)) { block in
        let configuration = ListItemStyleConfiguration(
          marker: .init(marker),
          block: .init(block),
          indentationLevel: indentationLevel
        )
        let resolvedStyle = listItemStyle.resolve(configuration: configuration)

        AnyView(resolvedStyle)
          // The style can place the block inside a container, which hides its spacing
          .containerValue(\.nestedBlockSpacing, block.blockSpacing)
      }
    }

    private var marker: some View {
      AnyView(
        unorderedListMarker.resolve(
          configuration: .init(
            indentationLevel: indentationLevel
          )
        )
      )
    }

    private var indentationLevel: Int {
      content.runs.first?.presentationIntent?.indentationLevel ?? 0
    }
  }
}
