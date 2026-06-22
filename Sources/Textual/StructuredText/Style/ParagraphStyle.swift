import SwiftUI

extension StructuredText {
  /// A style that controls how `StructuredText` renders paragraphs.
  ///
  /// You can set a paragraph style using the ``TextualNamespace/paragraphStyle(_:)`` modifier
  /// or through a bundled ``StructuredText/Style``.
  public protocol ParagraphStyle: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents a paragraph.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = BlockStyleConfiguration
  }
}

private struct ParagraphStyleKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.ParagraphStyle = .default
}

extension EnvironmentValues {
  @usableFromInline
  var paragraphStyle: any StructuredText.ParagraphStyle {
    get { self[ParagraphStyleKey.self] }
    set { self[ParagraphStyleKey.self] = newValue }
  }
}
