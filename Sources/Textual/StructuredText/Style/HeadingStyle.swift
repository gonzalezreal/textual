import SwiftUI

extension StructuredText {
  /// The properties of a heading passed to a `HeadingStyle`.
  public struct HeadingStyleConfiguration {
    /// A type-erased view that contains the heading content.
    public struct Label: View {
      init(_ label: some View) {
        self.body = AnyView(label)
      }
      public let body: AnyView
    }

    /// The heading content.
    public let label: Label
    /// The indentation level of the heading within the document structure.
    public let indentationLevel: Int
    /// The heading level, from `1` (most prominent) to `6` (least prominent).
    public let headingLevel: Int
  }

  /// A style that controls how `StructuredText` renders headings.
  ///
  /// Apply a heading style with ``TextualNamespace/headingStyle(_:)`` or through a bundled
  /// ``StructuredText/Style``.
  public protocol HeadingStyle: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents a heading.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = HeadingStyleConfiguration
  }
}

private struct HeadingStyleKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.HeadingStyle = .default
}

extension EnvironmentValues {
  @usableFromInline
  var headingStyle: any StructuredText.HeadingStyle {
    get { self[HeadingStyleKey.self] }
    set { self[HeadingStyleKey.self] = newValue }
  }
}
