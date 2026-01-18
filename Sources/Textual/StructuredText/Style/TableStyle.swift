import SwiftUI

extension StructuredText {
  /// The properties of a table passed to a `TableStyle`.
  public struct TableStyleConfiguration {
    /// A type-erased view that contains the table content.
    public struct Label: View {
      init(_ label: some View) {
        self.body = AnyView(label)
      }
      public let body: AnyView
    }

    /// The table content.
    public let label: Label

    /// The indentation level of the table within the document structure.
    public let indentationLevel: Int
  }

  /// A style that controls how `StructuredText` renders tables.
  ///
  /// You can apply a table style using the ``TextualNamespace/tableStyle(_:)`` modifier
  /// or through a bundled ``StructuredText/Style``.
  public protocol TableStyle: DynamicProperty {
    associatedtype Body: View
    associatedtype Background: View
    associatedtype Overlay: View

    /// Creates a view that represents a table.
    @MainActor @ViewBuilder
    func makeBody(configuration: Self.Configuration) -> Self.Body

    /// Creates the background content for a table.
    @MainActor @ViewBuilder
    func makeBackground(layout: TableLayout) -> Self.Background

    /// Creates the overlay content for a table.
    @MainActor @ViewBuilder
    func makeOverlay(layout: TableLayout) -> Self.Overlay

    typealias Configuration = TableStyleConfiguration
  }
}

extension StructuredText.TableStyle where Background == EmptyView {
  public func makeBackground(layout: StructuredText.TableLayout) -> EmptyView {
    EmptyView()
  }
}

extension StructuredText.TableStyle where Overlay == EmptyView {
  public func makeOverlay(layout: StructuredText.TableLayout) -> EmptyView {
    EmptyView()
  }
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var tableStyle: any StructuredText.TableStyle = .default
}
