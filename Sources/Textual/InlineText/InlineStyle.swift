import SwiftUI

/// Customizes the appearance of inline elements in ``InlineText`` and ``StructuredText``.
///
/// Use `InlineStyle` to control how inline formatting (code, emphasis, links, strong, and
/// strikethrough) is rendered. Apply a custom style using the ``TextualNamespace/inlineStyle(_:)`` modifier.
///
/// ```swift
/// let style = InlineStyle()
///   .code(.monospaced, .foregroundColor(.purple))
///   .strong(.fontWeight(.bold))
///   .link(.foregroundColor(.blue))
///
/// InlineText(markdown: "Use `git status` to check **uncommitted** changes")
///   .textual.inlineStyle(style)
/// ```
///
/// Each inline element can be customized independently using ``TextProperty`` values.
///
/// `InlineStyle()` creates a baseline style. By default, Textual uses ``InlineStyle/default`` in
/// the environment, which applies a slightly smaller monospaced font for code, semibold for
/// strong, and a link color that adapts to the current color scheme.
public struct InlineStyle: Sendable, Hashable {
  var code: AnyTextProperty = AnyTextProperty(.monospaced)
  var emphasis: AnyTextProperty = AnyTextProperty(.italic)
  var link: AnyTextProperty = AnyTextProperty(.foregroundColor(.accentColor))
  var strong: AnyTextProperty = AnyTextProperty(.bold)
  var strikethrough: AnyTextProperty = AnyTextProperty(.strikethroughStyle(.single))

  /// Creates an inline style with default formatting.
  public init() {}

  /// Returns a copy of this style with custom code formatting.
  ///
  /// - Parameter properties: Text properties to apply to inline code elements.
  /// - Returns: A new style with the modified code formatting.
  public func code<each P: TextProperty>(_ properties: repeat each P) -> Self {
    modifyingStyle { $0.code = AnyTextProperty(repeat each properties) }
  }

  /// Returns a copy of this style with custom emphasis formatting.
  ///
  /// - Parameter properties: Text properties to apply to emphasized text.
  /// - Returns: A new style with the modified emphasis formatting.
  public func emphasis<each P: TextProperty>(_ properties: repeat each P) -> Self {
    modifyingStyle { $0.emphasis = AnyTextProperty(repeat each properties) }
  }

  /// Returns a copy of this style with custom link formatting.
  ///
  /// - Parameter properties: Text properties to apply to links.
  /// - Returns: A new style with the modified link formatting.
  public func link<each P: TextProperty>(_ properties: repeat each P) -> Self {
    modifyingStyle { $0.link = AnyTextProperty(repeat each properties) }
  }

  /// Returns a copy of this style with custom strong formatting.
  ///
  /// - Parameter properties: Text properties to apply to strong (bold) text.
  /// - Returns: A new style with the modified strong formatting.
  public func strong<each P: TextProperty>(_ properties: repeat each P) -> Self {
    modifyingStyle { $0.strong = AnyTextProperty(repeat each properties) }
  }

  /// Returns a copy of this style with custom strikethrough formatting.
  ///
  /// - Parameter properties: Text properties to apply to strikethrough text.
  /// - Returns: A new style with the modified strikethrough formatting.
  public func strikethrough<each P: TextProperty>(_ properties: repeat each P) -> Self {
    modifyingStyle { $0.strikethrough = AnyTextProperty(repeat each properties) }
  }

  private func modifyingStyle(_ modify: (inout Self) -> Void) -> Self {
    var style = self
    modify(&style)
    return style
  }
}

private struct InlineStyleKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: InlineStyle = .default
}

extension EnvironmentValues {
  @usableFromInline
  var inlineStyle: InlineStyle {
    get { self[InlineStyleKey.self] }
    set { self[InlineStyleKey.self] = newValue }
  }
}
