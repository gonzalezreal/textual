import SwiftUI

// MARK: - Deprecated after 0.2.1

extension StructuredText {
  @available(*, deprecated, message: "Use 'init(markdown:baseURL:syntaxExtensions:)' instead.")
  @_disfavoredOverload
  public init(
    markdown: String,
    baseURL: URL? = nil,
    patternOptions: AttributedStringMarkdownParser.PatternOptions = .init()
  ) {
    self.init(
      markdown,
      parser: .markdown(
        baseURL: baseURL,
        patternOptions: patternOptions
      )
    )
  }
}

extension InlineText {
  @available(*, deprecated, message: "Use 'init(markdown:baseURL:syntaxExtensions:)' instead.")
  @_disfavoredOverload
  public init(
    markdown: String,
    baseURL: URL? = nil,
    patternOptions: AttributedStringMarkdownParser.PatternOptions = .init()
  ) {
    self.init(
      markdown,
      parser: .inlineMarkdown(
        baseURL: baseURL,
        patternOptions: patternOptions
      )
    )
  }
}

extension AttributedStringMarkdownParser {
  @available(*, deprecated, message: "Use 'SyntaxExtension' instead.")
  public struct PatternOptions: Hashable, Sendable {
    public var emoji: Set<Emoji>

    #if Math
      public var mathExpressions: Bool

      public init(emoji: Set<Emoji> = [], mathExpressions: Bool = false) {
        self.emoji = emoji
        self.mathExpressions = mathExpressions
      }
    #else
      public init(emoji: Set<Emoji> = []) {
        self.emoji = emoji
      }
    #endif
  }

  @available(*, deprecated, message: "Use 'init(baseURL:options:syntaxExtensions:)' instead.")
  @_disfavoredOverload
  public init(
    baseURL: URL?,
    options: AttributedString.MarkdownParsingOptions = .init(),
    patternOptions: PatternOptions = .init()
  ) {
    #if Math
      self.init(
        baseURL: baseURL,
        options: options,
        syntaxExtensions: [
          patternOptions.emoji.isEmpty ? nil : .emoji(patternOptions.emoji),
          patternOptions.mathExpressions ? .math : nil,
        ].compactMap(\.self)
      )
    #else
      self.init(
        baseURL: baseURL,
        options: options,
        syntaxExtensions: [
          patternOptions.emoji.isEmpty ? nil : .emoji(patternOptions.emoji)
        ].compactMap(\.self)
      )
    #endif
  }
}

extension MarkupParser where Self == AttributedStringMarkdownParser {
  @available(*, deprecated, message: "Use 'inlineMarkdown(baseURL:syntaxExtensions:)' instead.")
  @_disfavoredOverload
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

  @available(*, deprecated, message: "Use 'markdown(baseURL:syntaxExtensions:)' instead.")
  @_disfavoredOverload
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

// MARK: - Deprecated after 0.2.0

extension StructuredText.TableStyleConfiguration {
  @available(
    *, deprecated, message: "Use 'makeBackground(layout:)' or 'makeOverlay(layout:)' instead."
  )
  public var layout: StructuredText.TableLayout {
    .init()
  }
}

// MARK: - Deprecated after 0.1.1

extension EmojiProperties {
  @available(*, deprecated, message: "Use 'EmojiProperties()' instead.")
  public static let `default` = EmojiProperties()
}

extension AttachmentSelectionStyle {
  @available(*, deprecated, renamed: "text")
  public static let inline: AttachmentSelectionStyle = .text
}

extension InlineText {
  @available(*, deprecated, renamed: "init(markdown:baseURL:patternOptions:)")
  @_disfavoredOverload
  public init(
    markdown: String,
    baseURL: URL? = nil,
    preprocessingOptions: AttributedStringMarkdownParser.PreprocessingOptions = .init()
  ) {
    self.init(
      markdown: markdown,
      baseURL: baseURL,
      patternOptions: preprocessingOptions
    )
  }
}

extension StructuredText {
  @available(*, deprecated, renamed: "init(markdown:baseURL:patternOptions:)")
  @_disfavoredOverload
  public init(
    markdown: String,
    baseURL: URL? = nil,
    preprocessingOptions: AttributedStringMarkdownParser.PreprocessingOptions = .init()
  ) {
    self.init(
      markdown: markdown,
      baseURL: baseURL,
      patternOptions: preprocessingOptions
    )
  }
}

extension AttributedStringMarkdownParser {
  @available(*, deprecated, renamed: "PatternOptions")
  public typealias PreprocessingOptions = PatternOptions

  @available(*, deprecated, renamed: "init(baseURL:options:patternOptions:)")
  @_disfavoredOverload
  public init(
    baseURL: URL?,
    options: AttributedString.MarkdownParsingOptions = .init(),
    preprocessingOptions: PreprocessingOptions = .init()
  ) {
    self.init(baseURL: baseURL, options: options, patternOptions: preprocessingOptions)
  }
}

extension MarkupParser where Self == AttributedStringMarkdownParser {
  @available(*, deprecated, renamed: "inlineMarkdown(baseURL:patternOptions:)")
  @_disfavoredOverload
  public static func inlineMarkdown(
    baseURL: URL? = nil,
    preprocessingOptions: AttributedStringMarkdownParser.PreprocessingOptions = .init()
  ) -> Self {
    inlineMarkdown(baseURL: baseURL, patternOptions: preprocessingOptions)
  }

  @available(*, deprecated, renamed: "markdown(baseURL:patternOptions:)")
  @_disfavoredOverload
  public static func markdown(
    baseURL: URL? = nil,
    preprocessingOptions: AttributedStringMarkdownParser.PreprocessingOptions = .init()
  ) -> Self {
    markdown(baseURL: baseURL, patternOptions: preprocessingOptions)
  }
}
