import Testing

@testable import Textual

@MainActor
struct MarkupParseCacheTests {
  @Test func reusesTheParseForTheSameMarkupAndParser() {
    let cache = MarkupParseCache()
    let first = cache.attributedString(for: "**bold**", parser: .markdown())
    let second = cache.attributedString(for: "**bold**", parser: .markdown())
    #expect(first == second)
  }

  @Test func reparsesWhenTheParserChanges() {
    let cache = MarkupParseCache()
    let plain = cache.attributedString(for: "$x$", parser: .markdown())
    let math = cache.attributedString(for: "$x$", parser: .markdown(syntaxExtensions: [.math]))
    #expect(plain != math)
  }

  @Test func parsersWithTheSameConfigurationShareAKey() {
    #expect(AttributedStringMarkdownParser.markdown().cacheKey == AttributedStringMarkdownParser.markdown().cacheKey)
    #expect(AttributedStringMarkdownParser.markdown().cacheKey != AttributedStringMarkdownParser.inlineMarkdown().cacheKey)
    #expect(
      AttributedStringMarkdownParser.markdown(syntaxExtensions: [.math]).cacheKey
        != AttributedStringMarkdownParser.markdown().cacheKey
    )
  }
}
