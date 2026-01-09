import Foundation

/// A ``MarkupParser`` implementation backed by Foundation’s Markdown support.
///
/// This parser uses `AttributedString(markdown:...)` under the hood. Use it when your input is
/// Markdown and you want Textual to preserve structure via Foundation attributes such as
/// `PresentationIntent`, inline presentation intents, links, and image URLs.
///
/// Textual also supports a postprocessing step for custom emoji substitution.
public struct AttributedStringMarkdownParser: MarkupParser {
  /// Options that control pattern expansion after Markdown parsing.
  public struct PatternOptions: Hashable, Sendable {
    /// A set of custom emoji definitions used to expand `:shortcode:` sequences.
    public var emoji: Set<Emoji>

    public var processesMathExpressions: Bool

    /// Creates postprocessing options.
    public init(emoji: Set<Emoji> = [], processesMathExpressions: Bool = false) {
      self.emoji = emoji
      self.processesMathExpressions = processesMathExpressions
    }
  }

  private let baseURL: URL?
  private let options: AttributedString.MarkdownParsingOptions
  private let processor: PatternProcessor

  public init(
    baseURL: URL?,
    options: AttributedString.MarkdownParsingOptions = .init(),
    patternOptions: PatternOptions = .init()
  ) {
    self.baseURL = baseURL
    self.options = options
    self.processor = PatternProcessor(
      rules: [
        patternOptions.emoji.isEmpty ? nil : .emoji(patternOptions.emoji),
        patternOptions.processesMathExpressions ? .math : nil,
      ].compactMap(\.self)
    )
  }

  public func attributedString(for input: String) throws -> AttributedString {
    try processor.expand(
      AttributedString(
        markdown: input,
        including: \.textual,
        options: options,
        baseURL: baseURL
      )
    )
  }
}

extension MarkupParser where Self == AttributedStringMarkdownParser {
  /// Creates a Markdown parser configured for inline-only syntax.
  public static func inlineMarkdown(
    baseURL: URL? = nil,
    patternOptions: AttributedStringMarkdownParser.PatternOptions = .init()
  ) -> Self {
    .init(
      baseURL: baseURL,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace),
      patternOptions: patternOptions
    )
  }

  /// Creates a Markdown parser configured for full-document syntax.
  public static func markdown(
    baseURL: URL? = nil,
    patternOptions: AttributedStringMarkdownParser.PatternOptions = .init()
  ) -> Self {
    .init(
      baseURL: baseURL,
      patternOptions: patternOptions
    )
  }
}
