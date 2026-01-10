import Foundation

/// A ``MarkupParser`` implementation backed by Foundation’s Markdown support.
///
/// This parser leverages Foundation’s Markdown support and preserves structure via
/// presentation intents.
///
/// This parser can process its output to expand custom emoji and math expressions into
/// inline attachments.
public struct AttributedStringMarkdownParser: MarkupParser {
  /// Options that control pattern expansion after Markdown parsing.
  public struct PatternOptions: Hashable, Sendable {
    /// A set of custom emoji definitions used to expand `:shortcode:` sequences.
    public var emoji: Set<Emoji>

    /// Enables processing of math expressions into attachments.
    public var mathExpressions: Bool

    /// Creates pattern options.
    public init(emoji: Set<Emoji> = [], mathExpressions: Bool = false) {
      self.emoji = emoji
      self.mathExpressions = mathExpressions
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
        patternOptions.mathExpressions ? .math : nil,
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
