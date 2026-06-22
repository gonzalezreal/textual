import SwiftUI

extension StructuredText {
  /// A theme used to style syntax-highlighted code blocks.
  ///
  /// A `HighlighterTheme` defines the base foreground and background colors for code blocks and
  /// an optional set of token-specific text properties.
  ///
  /// You can set a highlighter theme using the ``TextualNamespace/highlighterTheme(_:)`` modifier.
  public struct HighlighterTheme: Hashable, Sendable {
    let foregroundColor: DynamicColor
    let backgroundColor: DynamicColor
    let tokenProperties: [TokenType: AnyTextProperty]

    /// Creates a highlighter theme.
    ///
    /// - Parameters:
    ///   - foregroundColor: The default text color for code blocks.
    ///   - backgroundColor: The background color for code blocks.
    ///   - tokenProperties: Token-specific text properties. Token types are identified by a
    ///     string, for example `"keyword"` or `"comment"`.
    public init(
      foregroundColor: DynamicColor,
      backgroundColor: DynamicColor,
      tokenProperties: [TokenType: AnyTextProperty] = [:]
    ) {
      self.foregroundColor = foregroundColor
      self.backgroundColor = backgroundColor
      self.tokenProperties = tokenProperties
    }
  }
}

private struct HighlighterThemeKey: EnvironmentKey {
  static let defaultValue: StructuredText.HighlighterTheme = .default
}

extension EnvironmentValues {
  @usableFromInline
  var highlighterTheme: StructuredText.HighlighterTheme {
    get { self[HighlighterThemeKey.self] }
    set { self[HighlighterThemeKey.self] = newValue }
  }
}
