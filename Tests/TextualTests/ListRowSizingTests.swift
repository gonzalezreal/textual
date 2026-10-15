#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import UIKit

  import Textual

  // A `List` measures each row when it first lays it out. If the row's height changes after that,
  // the list moves every row below it, and the content jumps while scrolling. The same goes for
  // `UIHostingConfiguration` cells in a collection view, which is how a `List` hosts its rows too.
  @MainActor
  struct ListRowSizingTests {
    @Test func inlineTextRowsKeepTheirFirstHeight() throws {
      let heights = try rowHeights(for: Self.inlineMarkdown) {
        InlineText(markdown: $0)
      }

      #expect(heights.resizedRows.isEmpty, "\(heights.summary)")
    }

    @Test func structuredTextRowsKeepTheirFirstHeight() throws {
      let heights = try rowHeights(for: Self.markdown) {
        StructuredText(markdown: $0)
      }

      #expect(heights.resizedRows.isEmpty, "\(heights.summary)")
    }

    @Test func structuredTextCellsKeepTheirFirstHeight() throws {
      let heights = RowHeights()
      let rows = (0..<60).map { Self.markdown[$0 % Self.markdown.count] }
      let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewCompositionalLayout.list(
          using: UICollectionLayoutListConfiguration(appearance: .plain)
        )
      )
      let cell = UICollectionView.CellRegistration<UICollectionViewCell, Int> { cell, _, index in
        cell.contentConfiguration = UIHostingConfiguration {
          StructuredText(markdown: rows[index])
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self, of: \.size.height) {
              heights.record($0, row: index)
            }
            .id(index)
        }
      }
      let dataSource = UICollectionViewDiffableDataSource<Int, Int>(
        collectionView: collectionView
      ) {
        $0.dequeueConfiguredReusableCell(using: cell, for: $1, item: $2)
      }
      var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
      snapshot.appendSections([0])
      snapshot.appendItems(Array(rows.indices))
      dataSource.apply(snapshot, animatingDifferences: false)

      let viewController = UIViewController()
      viewController.view = collectionView
      let window = TestWindow(viewController)
      withExtendedLifetime(dataSource) {
        scrollToEndAndBack(collectionView, window: window)
      }

      #expect(heights.rowCount == rows.count)
      #expect(heights.resizedRows.isEmpty, "\(heights.summary)")
    }

    private func rowHeights(
      for markup: [String],
      @ViewBuilder row: @escaping (String) -> some View
    ) throws -> RowHeights {
      let heights = RowHeights()
      let rows = (0..<60).map { markup[$0 % markup.count] }
      let window = TestWindow(
        List(rows.indices, id: \.self) { index in
          row(rows[index])
            .onGeometryChange(for: CGFloat.self, of: \.size.height) {
              heights.record($0, row: index)
            }
        }
        .listStyle(.plain)
      )
      scrollToEndAndBack(try #require(window.scrollView), window: window)

      #expect(heights.rowCount == rows.count)
      return heights
    }

    // Lays out every row, and lays out some of them again on the way back
    private func scrollToEndAndBack(
      _ scrollView: UIScrollView, window: TestWindow<some UIViewController>
    ) {
      for direction: CGFloat in [1, -1] {
        for _ in 0..<40 {
          let offset = scrollView.contentOffset.y + direction * scrollView.bounds.height / 3
          scrollView.contentOffset.y = min(
            max(offset, -scrollView.adjustedContentInset.top),
            scrollView.contentSize.height - scrollView.bounds.height
              + scrollView.adjustedContentInset.bottom
          )
          window.settle()
        }
      }
    }
  }

  extension ListRowSizingTests {
    /// The heights each row went through, in the order the list laid them out.
    @MainActor
    final class RowHeights {
      private var heights: [Int: [CGFloat]] = [:]

      var rowCount: Int {
        heights.count
      }

      var resizedRows: [Int] {
        heights.filter { $0.value.count > 1 }.keys.sorted()
      }

      var summary: String {
        let examples = resizedRows.prefix(4).map { row in
          "row \(row): \(heights[row, default: []].map { Int($0.rounded()) })"
        }
        return "\(resizedRows.count) of \(rowCount) rows changed height after their first layout"
          + (examples.isEmpty ? "" : ", " + examples.joined(separator: ", "))
      }

      func record(_ height: CGFloat, row: Int) {
        if let last = heights[row]?.last, abs(last - height) < 0.5 {
          return
        }
        heights[row, default: []].append(height)
      }
    }

    fileprivate static let inlineMarkdown = [
      "Use `git status` to check **uncommitted** changes.",
      "A *short* one.",
      """
      Read the [contributing guide](https://example.com) first, then open a pull request that \
      explains what changed and why, so reviewers know where to look.
      """,
      "**Bold**, *italic*, ~~strikethrough~~ and `code` in a line that wraps on a phone.",
    ]

    fileprivate static let markdown = [
      """
      The sky above the port was the color of television, tuned to a dead channel.

      It was a bright cold day in April, and the clocks were striking thirteen.
      """,
      """
      ## A heading

      A paragraph under a heading, with `code` and **strong** text.
      """,
      """
      Things to pack:

      - A towel
      - A **guide**
      - A sense of humor that survives the end of the world
      """,
      """
      1. First
      2. Second, with enough text to wrap onto the next line on a phone
      3. Third
      """,
      "> A block quote with *emphasis*.",
      "A single paragraph.",
    ]
  }
#endif
