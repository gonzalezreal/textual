import SwiftUI

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
