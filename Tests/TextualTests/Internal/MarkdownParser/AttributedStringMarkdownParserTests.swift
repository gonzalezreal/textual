import Foundation
import Testing

@testable import Textual

extension AttributedStringMarkdownParser {
  @MainActor
  struct ParserTests {
    @Test func parsesLinkedImage() throws {
      let parser = AttributedStringMarkdownParser(baseURL: nil)

      let output = try parser.attributedString(
        for: "[![](https://example.com/a.png)](https://example.com/b.png)"
      )

      let run = try #require(output.runs.first)
      #expect(String(output.characters[...]) == "\u{FFFC}")
      #expect(run.imageURL == URL(string: "https://example.com/a.png"))
      #expect(run.link == URL(string: "https://example.com/b.png"))
    }

    @Test func parsesLinkedImageWithAltText() throws {
      let parser = AttributedStringMarkdownParser(baseURL: nil)

      let output = try parser.attributedString(
        for: "[![Alt](https://example.com/a.png)](https://example.com/b.png)"
      )

      let run = try #require(output.runs.first)
      #expect(String(output.characters[...]) == "Alt")
      #expect(run.imageURL == URL(string: "https://example.com/a.png"))
      #expect(run.link == URL(string: "https://example.com/b.png"))
    }

    @Test func preservesTextAroundLinkedImage() throws {
      let parser = AttributedStringMarkdownParser(baseURL: nil)

      let output = try parser.attributedString(
        for: "before [![](https://example.com/a.png)](https://example.com/b.png) after"
      )

      let imageRun = try #require(output.runs.first { $0.imageURL != nil })
      #expect(String(output.characters[...]) == "before \u{FFFC} after")
      #expect(imageRun.imageURL == URL(string: "https://example.com/a.png"))
      #expect(imageRun.link == URL(string: "https://example.com/b.png"))
    }

    @Test func resolvesLinkedImageRelativeURLs() throws {
      let parser = AttributedStringMarkdownParser(
        baseURL: URL(string: "https://example.com/repo/")!
      )

      let output = try parser.attributedString(for: "[![](assets/a.png)](docs/b)")

      let run = try #require(output.runs.first)
      #expect(
        run.imageURL?.absoluteURL == URL(string: "https://example.com/repo/assets/a.png")
      )
      #expect(run.link?.absoluteURL == URL(string: "https://example.com/repo/docs/b"))
    }

    @Test func ignoresLinkedImageInInlineCode() throws {
      let parser = AttributedStringMarkdownParser(baseURL: nil)

      let output = try parser.attributedString(
        for: "`[![](https://example.com/a.png)](https://example.com/b.png)`"
      )

      let run = try #require(output.runs.first)
      #expect(
        String(output.characters[...])
          == "[![](https://example.com/a.png)](https://example.com/b.png)"
      )
      #expect(run.imageURL == nil)
      #expect(run.link == nil)
    }

    @Test func ignoresLinkedImageInCodeBlock() throws {
      let parser = AttributedStringMarkdownParser(baseURL: nil)

      let output = try parser.attributedString(
        for: """
          ```
          [![](https://example.com/a.png)](https://example.com/b.png)
          ```
          """
      )

      #expect(output.runs.allSatisfy { $0.imageURL == nil && $0.link == nil })
    }
  }
}
