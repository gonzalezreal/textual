import SwiftUI
private import SwiftUIMath

/// Properties that control how Textual renders math expressions.
public struct MathProperties: Sendable, Hashable {
  public struct FontName: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
      self.rawValue = value
    }
  }

  /// The math font family to use.
  public var fontName: FontName

  /// Scales the math font relative to the surrounding text.
  public var fontScale: CGFloat

  /// The alignment applied to block math paragraphs.
  public var textAlignment: TextAlignment

  public init(
    fontName: FontName = .latinModern,
    fontScale: CGFloat = 1.2,
    textAlignment: TextAlignment = .center
  ) {
    self.fontName = fontName
    self.fontScale = fontScale
    self.textAlignment = textAlignment
  }
}

extension MathProperties.FontName {
  public static let latinModern: Self = .init(rawValue: Math.Font.Name.latinModern.rawValue)
  public static let kpMathLight: Self = .init(rawValue: Math.Font.Name.kpMathLight.rawValue)
  public static let kpMathSans: Self = .init(rawValue: Math.Font.Name.kpMathSans.rawValue)
  public static let xits: Self = .init(rawValue: Math.Font.Name.xits.rawValue)
  public static let termes: Self = .init(rawValue: Math.Font.Name.termes.rawValue)
  public static let asana: Self = .init(rawValue: Math.Font.Name.asana.rawValue)
  public static let euler: Self = .init(rawValue: Math.Font.Name.euler.rawValue)
  public static let fira: Self = .init(rawValue: Math.Font.Name.fira.rawValue)
  public static let notoSans: Self = .init(rawValue: Math.Font.Name.notoSans.rawValue)
  public static let libertinus: Self = .init(rawValue: Math.Font.Name.libertinus.rawValue)
  public static let garamond: Self = .init(rawValue: Math.Font.Name.garamond.rawValue)
  public static let leteSans: Self = .init(rawValue: Math.Font.Name.leteSans.rawValue)
}

extension EnvironmentValues {
  @Entry var mathProperties = MathProperties()
}
