import SwiftUI

extension StructuredText {
  /// The properties of a list item passed to a `ListItemStyle`.
  public struct ListItemStyleConfiguration {
    /// A type-erased view that contains the list marker (bullet, number, and so on).
    public struct Marker: View {
      init(_ marker: some View) {
        if let marker = marker as? AnyView {
          self.body = marker
        } else {
          self.body = AnyView(marker)
        }
      }
      public let body: AnyView
    }

    /// A type-erased view that contains the list item content.
    public struct Block: View {
      init(_ block: some View) {
        self.body = AnyView(block)
      }
      public let body: AnyView
    }

    /// The marker view.
    public let marker: Marker
    /// The list item content.
    public let block: Block
    /// The indentation level of the list item within the document structure.
    public let indentationLevel: Int
  }

  /// A style that controls how `StructuredText` lays out list items.
  ///
  /// Apply a list item style with ``TextualNamespace/listItemStyle(_:)`` or through a bundled
  /// ``StructuredText/Style``.
  public protocol ListItemStyle: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents a list item.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = ListItemStyleConfiguration
  }
}

private struct ListItemStyleKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.ListItemStyle = .default
}

extension EnvironmentValues {
  @usableFromInline
  var listItemStyle: any StructuredText.ListItemStyle {
    get { self[ListItemStyleKey.self] }
    set { self[ListItemStyleKey.self] = newValue }
  }
}
