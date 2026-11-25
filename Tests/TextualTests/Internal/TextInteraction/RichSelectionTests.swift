#if os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct RichSelectionTests {
    @Test func copyAcrossProseCodeAndTable() async throws {
      let markdown = """
        **bold** and `inline`

        ```swift
        let n = 42
        ```

        | Key | Value |
        | --- | --- |
        | one | *two* |
        """
      try await withSelection(markdown: markdown, containing: "two") { view, pasteboard in
        view.copySelection(to: pasteboard)
        let html = try #require(pasteboard.string(forType: .html))
        #expect(html.contains("<strong>bold</strong>"))
        #expect(html.contains("<code>inline</code>"))
        #expect(html.contains("<pre><code"))
        #expect(html.contains("let n = 42"))
        #expect(html.contains("<table>"))
        #expect(html.contains(">Key</th>"))
        #expect(html.contains(">one</td>"))
        #expect(html.contains("<em>two</em>"))

        let receiver = NSTextView()
        receiver.isRichText = true
        try #require(receiver.readSelection(from: pasteboard))
        let pasted = receiver.attributedString()
        for (word, trait) in [
          ("bold", NSFontDescriptor.SymbolicTraits.bold), ("inline", .monoSpace),
          ("let n", .monoSpace), ("two", .italic),
        ] {
          let location = (pasted.string as NSString).range(of: word).location
          try #require(location != NSNotFound)
          let font = try #require(
            pasted.attribute(.font, at: location, effectiveRange: nil) as? NSFont)
          #expect(font.fontDescriptor.symbolicTraits.contains(trait))
        }
        let cell = (pasted.string as NSString).range(of: "one").location
        try #require(cell != NSNotFound)
        let style = try #require(
          pasted.attribute(.paragraphStyle, at: cell, effectiveRange: nil) as? NSParagraphStyle)
        #expect(style.textBlocks.contains { $0 is NSTextTableBlock })
      }
    }

    @Test func copyPartOfBoldRun() async throws {
      try await withSelection(markdown: "**bold**", containing: "bold") { view, pasteboard in
        let start = try #require(view.model.position(from: view.model.startPosition, offset: 1))
        let end = try #require(view.model.position(from: start, offset: 2))
        view.model.selectedRange = TextRange(from: start, to: end)
        view.copySelection(to: pasteboard)
        #expect(pasteboard.string(forType: .html) == "<p><strong>ol</strong></p>")
        #expect(pasteboard.string(forType: .string) == "ol")
      }
    }

    @Test func copyWithoutSelectionPreservesPasteboard() async throws {
      try await withSelection(markdown: "Text", containing: "Text") { view, pasteboard in
        pasteboard.setString("Previous contents", forType: .string)
        view.model.selectedRange = nil
        view.copySelection(to: pasteboard)
        #expect(pasteboard.string(forType: .string) == "Previous contents")
      }
    }
  }

  // MARK: - Selection fixture

  extension RichSelectionTests {
    private func withSelection(
      markdown: String, containing lastText: String,
      _ check: (NSTextInteractionView, NSPasteboard) throws -> Void
    ) async throws {
      let host = NSHostingView(
        rootView: StructuredText(markdown: markdown)
          .textual.overflowMode(.wrap)
          .textual.textSelection(.enabled))
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
        styleMask: [], backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      window.contentView = host
      defer { window.close() }
      let pasteboard = NSPasteboard.withUniqueName()
      defer { pasteboard.releaseGlobally() }

      func interactionView(in view: NSView) -> NSTextInteractionView? {
        (view as? NSTextInteractionView)
          ?? view.subviews.lazy.compactMap { interactionView(in: $0) }.first
      }
      let deadline = ContinuousClock.now + .seconds(5)
      repeat {
        host.layoutSubtreeIfNeeded()
        if let view = interactionView(in: host), view.model.hasText {
          view.selectAll(nil)
          if let range = view.model.selectedRange, view.model.text(in: range).contains(lastText) {
            try check(view, pasteboard)
            return
          }
        }
        try await Task.sleep(for: .milliseconds(10))
      } while .now < deadline
      Issue.record("The selection did not include '\(lastText)' before the layout deadline.")
    }
  }
#endif
