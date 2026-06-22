import SwiftUI

extension StructuredText {
  /// A style that controls how `StructuredText` renders thematic breaks.
  ///
  /// You can apply a thematic break style using the ``TextualNamespace/thematicBreakStyle(_:)`` modifier
  /// or through a bundled ``StructuredText/Style``.
  public protocol ThematicBreakStyle: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents a thematic break.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = BlockStyleConfiguration
  }
}

private struct ThematicBreakStyleKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.ThematicBreakStyle = .divider
}

extension EnvironmentValues {
  @usableFromInline
  var thematicBreakStyle: any StructuredText.ThematicBreakStyle {
    get { self[ThematicBreakStyleKey.self] }
    set { self[ThematicBreakStyleKey.self] = newValue }
  }
}
