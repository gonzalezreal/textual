import SwiftUI

// MARK: - Overview
//
// OrderedList aligns all list item markers to a consistent width for uniform layout. Each marker
// measures itself and reports its width via preferences. The maximum width is taken and applied
// to all markers, ensuring alignment even when marker widths vary (e.g., "1." vs "10.").

extension StructuredText {
  struct OrderedList: View {
    @Environment(\.listItemSpacing) private var listItemSpacing
    @Environment(\.textEnvironment) private var textEnvironment

    @State private var markerWidth: CGFloat?

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

          OrderedListItem(
            intent: run.intent,
            content: content[run.range],
            markerWidth: markerWidth
          )
        }
      }
      .onPreferenceChange(MarkerWidthKey.self) { @MainActor in
        markerWidth = $0
      }
      .environment(\.resolvedListItemSpacing, listItemSpacing.resolve(in: textEnvironment))
      .environment(\.listItemSpacingEnabled, true)
    }
  }
}

extension StructuredText {
  fileprivate struct OrderedListItem: View {
    @Environment(\.listItemStyle) private var listItemStyle
    @Environment(\.orderedListMarker) private var orderedListMarker

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring
    private let markerWidth: CGFloat?

    init(
      intent: PresentationIntent.IntentType?,
      content: AttributedSubstring,
      markerWidth: CGFloat?
    ) {
      self.intent = intent
      self.content = content
      self.markerWidth = markerWidth
    }

    var body: some View {
      let configuration = ListItemStyleConfiguration(
        marker: .init(marker),
        block: .init(
          BlockContent(
            parent: intent,
            content: content
          )
        ),
        indentationLevel: indentationLevel
      )
      let resolvedStyle = listItemStyle.resolve(configuration: configuration)

      AnyView(resolvedStyle)
    }

    private var marker: some View {
      AnyView(
        orderedListMarker.resolve(
          configuration: .init(
            indentationLevel: indentationLevel,
            ordinal: ordinal
          )
        )
      )
      .background {
        // Propagate the marker width
        GeometryReader { proxy in
          Color.clear
            .preference(
              key: MarkerWidthKey.self,
              value: proxy.size.width
            )
        }
      }
      .frame(width: markerWidth, alignment: .trailing)
    }

    private var indentationLevel: Int {
      content.runs.first?.presentationIntent?.indentationLevel ?? 0
    }

    private var ordinal: Int {
      guard case .listItem(let ordinal) = intent?.kind else {
        return 0
      }
      return ordinal
    }
  }

  fileprivate struct MarkerWidthKey: PreferenceKey {
    static let defaultValue: CGFloat? = nil

    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
      value = [value, nextValue()].compactMap(\.self).max()
    }
  }
}
