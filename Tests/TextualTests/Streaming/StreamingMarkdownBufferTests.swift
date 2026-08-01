import Foundation
import Testing

@testable import Textual

private final class MutableClock: @unchecked Sendable {
  var now: Date
  init(now: Date) { self.now = now }
}

struct StreamingMarkdownBufferTests {
  @Test func pureAppendNeedsNoWithholding() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("Hello, ") == "Hello, ")
    #expect(buffer.append("world!") == "Hello, world!")
  }

  @Test func withholdsUnclosedStrongAcrossChunkBoundary() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("Hello **wor") == "Hello ")
    #expect(buffer.append("ld") == "Hello ")
    #expect(buffer.append("**!") == "Hello **world**!")
  }

  @Test func withholdsUnclosedEmphasis() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("This is *ital") == "This is ")
    #expect(buffer.append("ic*.") == "This is *italic*.")
  }

  @Test func withholdsUnclosedInlineCode() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("Run `git sta") == "Run ")
    #expect(buffer.append("tus`.") == "Run `git status`.")
  }

  @Test func withholdsUnclosedCodeFenceEntirely() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("Before\n```swift\nlet x = 1\n") == "Before\n")
    #expect(buffer.append("let y = 2\n") == "Before\n")
    #expect(buffer.append("```\nAfter") == "Before\n```swift\nlet x = 1\nlet y = 2\n```\nAfter")
  }

  @Test func withholdsInProgressLink() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("See [docs](https://exa") == "See ")
    #expect(buffer.append("mple.com") == "See ")
    #expect(buffer.append(") for more.") == "See [docs](https://example.com) for more.")
  }

  @Test func bracketsWithoutParenAreNotTreatedAsLinks() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("Use [brackets] like this.") == "Use [brackets] like this.")
  }

  @Test func multipleConstructsResolveInOrder() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("**bold** and *italic* and `code`") == "**bold** and *italic* and `code`")
  }

  @Test func pendingConstructReleasedAfterTimeout() {
    let clock = MutableClock(now: Date(timeIntervalSince1970: 0))
    var buffer = StreamingMarkdownBuffer(pendingTimeout: 1.0, currentDate: { clock.now })

    #expect(buffer.append("2 * 3 = 6, and **unfin") == "2 * 3 = 6, and ")

    clock.now.addTimeInterval(0.5)
    #expect(buffer.append("ished") == "2 * 3 = 6, and ")

    clock.now.addTimeInterval(0.6)
    #expect(buffer.append(" text") == "2 * 3 = 6, and **unfinished text")
  }

  @Test func flushReleasesWithheldTail() {
    var buffer = StreamingMarkdownBuffer()

    #expect(buffer.append("Ends mid **bold") == "Ends mid ")
    #expect(buffer.flush() == "Ends mid **bold")
  }

  @Test func flushIsIdempotentAndFutureAppendsContinueNormally() {
    var buffer = StreamingMarkdownBuffer()

    _ = buffer.append("mid **bold")
    #expect(buffer.flush() == "mid **bold")
    #expect(buffer.append(" more") == "mid **bold more")
  }
}
