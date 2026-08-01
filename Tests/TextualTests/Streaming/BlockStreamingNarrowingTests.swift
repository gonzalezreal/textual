#if os(macOS)
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct BlockStreamingNarrowingTests {
    @Test func rendersStreamingParagraphsWithoutCrashing() {
      #expect(render(markdown: "First paragraph.\n\nSecond paragraph.\n\nThird, still growing"))
    }

    @Test func rendersStreamingUnorderedListWithoutCrashing() {
      #expect(
        render(
          markdown: """
            - First item
            - Second item
            - Third item, still growin
            """
        )
      )
    }

    @Test func rendersStreamingOrderedListWithoutCrashing() {
      #expect(
        render(
          markdown: """
            1. First item
            1. Second item
            1. Third item, still growin
            """
        )
      )
    }

    @Test func rendersStreamingNestedListWithoutCrashing() {
      #expect(
        render(
          markdown: """
            - Outer item one
            - Outer item two
              - Nested item one
              - Nested item two, still growin
            """
        )
      )
    }

    @Test func rendersStreamingBlockQuoteContainingListWithoutCrashing() {
      #expect(
        render(
          markdown: """
            > A quote with a list:
            > - one
            > - two, still growin
            """
        )
      )
    }

    @Test func rendersStreamingTableWithoutCrashing() {
      #expect(
        render(
          markdown: """
            | A | B |
            |---|---|
            | one | two |
            | three | still growin
            """
        )
      )
    }

    @Test func rendersStreamingTableFollowedByParagraphWithoutCrashing() {
      // Once a later block arrives, the table is no longer "last" — exercises the settle
      // transition (every cell should snap to full opacity, not stay ghosted).
      #expect(
        render(
          markdown: """
            | A | B |
            |---|---|
            | one | two |

            A paragraph after the table, still growin
            """
        )
      )
    }

    private func render(markdown: String) -> Bool {
      let renderer = ImageRenderer(
        content: StructuredText(markdown: markdown)
          .textual.textStreaming(true)
          .textual.revealAnimation(.default)
          .frame(width: 320)
          .fixedSize(horizontal: false, vertical: true)
      )
      renderer.proposedSize = .init(width: 320, height: 400)

      return renderer.nsImage != nil
    }
  }
#endif
