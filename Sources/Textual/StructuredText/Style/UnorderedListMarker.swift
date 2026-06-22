import SwiftUI

extension StructuredText {
  /// The properties of an unordered-list marker passed to an `UnorderedListMarker`.
  public struct UnorderedListMarkerConfiguration {
    /// The indentation level of the list within the document structure.
    public let indentationLevel: Int
  }

  /// A marker view used for unordered list items (for example, a bullet).
  ///
  /// You can apply an unordered list marker using the ``TextualNamespace/unorderedListMarker(_:)`` modifier
  /// or through a bundled ``StructuredText/Style``.
  public protocol UnorderedListMarker: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents the marker for a list item.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = UnorderedListMarkerConfiguration
  }
}

private struct UnorderedListMarkerKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.UnorderedListMarker = .disc
}

extension EnvironmentValues {
  @usableFromInline
  var unorderedListMarker: any StructuredText.UnorderedListMarker {
    get { self[UnorderedListMarkerKey.self] }
    set { self[UnorderedListMarkerKey.self] = newValue }
  }
}

// MARK: - Symbol

extension StructuredText {
  /// A list marker that uses an SF Symbol.
  public struct SymbolListMarker: UnorderedListMarker {
    private let symbolName: String
    private let scale: CGFloat
    private let minWidth: FontScaled<CGFloat>

    /// Creates a symbol marker.
    ///
    /// - Parameters:
    ///   - symbolName: The SF Symbol name.
    ///   - scale: A font scale applied to the symbol.
    ///   - minWidth: A font-relative minimum width for the marker.
    public init(
      symbolName: String,
      scale: CGFloat = 1,
      minWidth: FontScaled<CGFloat> = .fontScaled(1.5)
    ) {
      self.symbolName = symbolName
      self.scale = scale
      self.minWidth = minWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
      SwiftUI.Image(systemName: symbolName)
        .textual.fontScale(scale)
        .textual.frame(minWidth: minWidth, alignment: .trailing)
    }
  }
}

extension StructuredText.UnorderedListMarker where Self == StructuredText.SymbolListMarker {
  /// A filled-circle marker.
  public static var disc: Self {
    .init(symbolName: "circle.fill", scale: 0.33)
  }

  /// An outlined-circle marker.
  public static var circle: Self {
    .init(symbolName: "circle", scale: 0.33)
  }

  /// A filled-square marker.
  public static var square: Self {
    .init(symbolName: "square.fill", scale: 0.33)
  }
}

// MARK: - Hierarchical

extension StructuredText {
  /// A marker that cycles through a list of symbol markers based on indentation level.
  public struct HierarchicalSymbolListMarker: UnorderedListMarker {
    private let markers: [SymbolListMarker]

    /// Creates a hierarchical marker from a variadic list of markers.
    public init(_ markers: SymbolListMarker...) {
      self.init(markers: markers)
    }

    init(markers: [SymbolListMarker]) {
      self.markers = markers
    }

    public func makeBody(configuration: Configuration) -> some View {
      markers[(configuration.indentationLevel - 1) % markers.count]
        .makeBody(configuration: configuration)
    }
  }
}

extension StructuredText.UnorderedListMarker
where Self == StructuredText.HierarchicalSymbolListMarker {
  /// Creates a hierarchical marker from a variadic list of markers.
  public static func hierarchical(_ markers: StructuredText.SymbolListMarker...) -> Self {
    .init(markers: markers)
  }
}

// MARK: - Dash

extension StructuredText {
  /// A list marker that renders a dash (`-`).
  public struct DashListMarker: UnorderedListMarker {
    private let minWidth: FontScaled<CGFloat>

    /// Creates a dash marker.
    ///
    /// - Parameter minWidth: A font-relative minimum width for the marker.
    public init(minWidth: FontScaled<CGFloat> = .fontScaled(1.5)) {
      self.minWidth = minWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
      Text("-")
        .textual.frame(minWidth: minWidth, alignment: .trailing)
    }
  }
}

extension StructuredText.UnorderedListMarker where Self == StructuredText.DashListMarker {
  /// The default dash marker.
  public static var dash: Self {
    .init()
  }
}
