import SwiftUI

extension StructuredText {
  /// The properties of an ordered-list marker passed to an `OrderedListMarker`.
  public struct OrderedListMarkerConfiguration {
    /// The indentation level of the list within the document structure.
    public let indentationLevel: Int
    /// The item number for this marker.
    public let ordinal: Int
  }

  /// A marker view used for ordered list items.
  ///
  /// Apply an ordered list marker with ``TextualNamespace/orderedListMarker(_:)`` or through a bundled
  /// ``StructuredText/Style``.
  public protocol OrderedListMarker: DynamicProperty {
    associatedtype Body: View

    /// Creates a view that represents the marker for a list item.
    @MainActor @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = OrderedListMarkerConfiguration
  }
}

private struct OrderedListMarkerKey: EnvironmentKey {
  nonisolated(unsafe) static let defaultValue: any StructuredText.OrderedListMarker = .decimal
}

extension EnvironmentValues {
  @usableFromInline
  var orderedListMarker: any StructuredText.OrderedListMarker {
    get { self[OrderedListMarkerKey.self] }
    set { self[OrderedListMarkerKey.self] = newValue }
  }
}

// MARK: - Decimal

extension StructuredText {
  /// A list marker that displays an item’s ordinal as a decimal number.
  public struct DecimalListMarker: OrderedListMarker {
    private let minWidth: FontScaled<CGFloat>

    /// Creates a decimal marker.
    ///
    /// - Parameter minWidth: A font-relative minimum width for the marker, useful for aligning
    ///   multi-digit ordinals.
    public init(minWidth: FontScaled<CGFloat> = .fontScaled(1.5)) {
      self.minWidth = minWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
      Text("\(configuration.ordinal).")
        .monospacedDigit()
        .textual.frame(minWidth: minWidth, alignment: .trailing)
    }
  }
}

extension StructuredText.OrderedListMarker where Self == StructuredText.DecimalListMarker {
  /// The default decimal ordered-list marker.
  public static var decimal: Self {
    .init()
  }
}

// MARK: - Ordinal mappings

extension StructuredText {
  /// A list marker that formats the item ordinal using a custom string transform.
  public struct MapOrdinalListMarker: OrderedListMarker {
    private let minWidth: FontScaled<CGFloat>
    private let transform: (Int) -> String

    /// Creates a marker that formats ordinals with `transform`.
    ///
    /// - Parameters:
    ///   - minWidth: A font-relative minimum width for the marker, useful for aligning markers.
    ///   - transform: A closure that converts the ordinal into a string (without the trailing period).
    public init(
      minWidth: FontScaled<CGFloat> = .fontScaled(1.5), transform: @escaping (Int) -> String
    ) {
      self.minWidth = minWidth
      self.transform = transform
    }

    public func makeBody(configuration: Configuration) -> some View {
      Text("\(transform(configuration.ordinal)).")
        .textual.frame(minWidth: minWidth, alignment: .trailing)
    }
  }
}

extension StructuredText.OrderedListMarker where Self == StructuredText.MapOrdinalListMarker {
  /// An ordered-list marker that uses uppercase Roman numerals.
  public static var upperRoman: Self {
    .init { $0.roman() }
  }

  /// An ordered-list marker that uses lowercase Roman numerals.
  public static var lowerRoman: Self {
    .init { $0.roman().lowercased() }
  }

  /// An ordered-list marker that uses uppercase letters.
  public static var upperAlpha: Self {
    .init(transform: \.upperAlpha)
  }

  /// An ordered-list marker that uses lowercase letters.
  public static var lowerAlpha: Self {
    .init(transform: \.lowerAlpha)
  }
}

// MARK: - Helpers

extension Int {
  fileprivate var lowerAlpha: String {
    guard self > 0, self <= 26 else {
      return String(self)
    }
    return String(UnicodeScalar(UInt8(96 + self)))
  }

  fileprivate var upperAlpha: String {
    guard self > 0, self <= 26 else {
      return String(self)
    }
    return String(UnicodeScalar(UInt8(64 + self)))
  }

  fileprivate func roman() -> String {
    guard self > 0, self < 4000 else {
      return "\(self)"
    }

    let decimals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
    let numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]

    var number = self
    var result = ""

    for (decimal, numeral) in zip(decimals, numerals) {
      let repeats = number / decimal
      if repeats > 0 {
        result += String(repeating: numeral, count: repeats)
      }
      number = number % decimal
    }

    return result
  }
}
