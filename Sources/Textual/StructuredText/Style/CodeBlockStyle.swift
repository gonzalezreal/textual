import SwiftUI

extension StructuredText {
  /// The properties of a code block passed to a `CodeBlockStyle`.
  public struct CodeBlockStyleConfiguration {
    /// A type-erased view that contains the code block content.
    public struct Label: View {
      init(_ label: some View) {
        self.body = AnyView(label)
      }
      public let body: AnyView
    }

    /// The code block content.
    public let label: Label
    /// The indentation level of the code block within the document structure.
    public let indentationLevel: Int
    /// A language hint extracted from the fenced code block, if present.
    public let languageHint: String?
    /// A proxy that provides code-block actions.
    public let codeBlock: CodeBlockProxy
    /// The syntax-highlighting theme used for this code block.
    public let highlighterTheme: HighlighterTheme
  }

  /// A style that controls how `StructuredText` renders code blocks.
  ///
  /// Apply a code block style with ``TextualNamespace/codeBlockStyle(_:)`` or through a bundled
  /// ``StructuredText/Style``.
  public protocol CodeBlockStyle: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents a code block.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = CodeBlockStyleConfiguration
  }
}

private struct CodeBlockStyleKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.CodeBlockStyle = .default
}

extension EnvironmentValues {
  @usableFromInline
  var codeBlockStyle: any StructuredText.CodeBlockStyle {
    get { self[CodeBlockStyleKey.self] }
    set { self[CodeBlockStyleKey.self] = newValue }
  }
}
