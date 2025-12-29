import SwiftUI

// MARK: - Overview
//
// Table uses a two-pass layout system. The first pass renders cells which emit their bounds via
// preferences. The second pass collects all cell bounds, transforms them from anchor coordinates
// to geometry coordinates, and creates a TableLayout that styles can use for rendering borders
// and backgrounds with precise cell positions.

extension StructuredText {
  struct Table: View {
    @Environment(\.tableStyle) private var tableStyle

    @State private var spacing = TableCell.Spacing()
    @State private var tableLayout = TableLayout()

    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring
    private let columns: [PresentationIntent.TableColumn]

    init(
      intent: PresentationIntent.IntentType?,
      content: AttributedSubstring,
      columns: [PresentationIntent.TableColumn]
    ) {
      self.intent = intent
      self.content = content
      self.columns = columns
    }

    var body: some View {
      let configuration = TableStyleConfiguration(
        label: .init(label),
        indentationLevel: indentationLevel,
        layout: tableLayout
      )
      let resolvedStyle = tableStyle.resolve(configuration: configuration)
        .onPreferenceChange(TableCell.SpacingKey.self) { @MainActor in
          spacing = $0
        }

      AnyView(resolvedStyle)
    }

    @ViewBuilder
    private var label: some View {
      let rowRuns = content.blockRuns(parent: intent)

      Grid(horizontalSpacing: spacing.horizontal, verticalSpacing: spacing.vertical) {
        ForEach(rowRuns.indices, id: \.self) { rowIndex in
          let rowRun = rowRuns[rowIndex]
          let rowContent = content[rowRun.range]
          let columnRuns = rowContent.blockRuns(parent: rowRun.intent)

          GridRow {
            ForEach(columnRuns.indices, id: \.self) { columnIndex in
              let cellRun = columnRuns[columnIndex]
              let cellContent = rowContent[cellRun.range]

              TableCell(cellContent, row: rowIndex, column: columnIndex)
                .gridColumnAlignment(alignment(for: columnIndex))
            }
          }
        }
      }
      .backgroundPreferenceValue(TableCell.BoundsKey.self) { values in
        GeometryReader { geometry in
          Color.clear
            .onChange(of: values, initial: true) { _, newValue in
              tableLayout = TableLayout(
                newValue.mapValues { geometry[$0] }
              )
            }
        }
      }
    }

    private var indentationLevel: Int {
      content.runs.first?.presentationIntent?.indentationLevel ?? 0
    }

    private func alignment(for columnIndex: Int) -> HorizontalAlignment {
      guard columnIndex < columns.count else {
        return .leading
      }

      switch columns[columnIndex].alignment {
      case .left:
        return .leading
      case .center:
        return .center
      case .right:
        return .trailing
      @unknown default:
        return .leading
      }
    }
  }
}
