import SwiftUI

/// A snapshot of SwiftUI text environment values.
///
/// Textual passes `TextEnvironmentValues` to APIs that need to resolve styling or sizing based on
/// the current environment, such as ``TextProperty`` and ``Attachment``.
public struct TextEnvironmentValues: Hashable, Sendable {
  /// The current font in the environment.
  public var font: Font?

  /// The current dynamic type size in the environment.
  public var dynamicTypeSize: DynamicTypeSize

  /// The current legibility weight in the environment.
  public var legibilityWeight: LegibilityWeight?

  /// Properties that control how Textual renders emoji.
  public var emojiProperties: EmojiProperties

  /// Properties that control how Textual renders math expressions.
  public var mathProperties: MathProperties

  /// The current color scheme in the environment.
  public var colorScheme: ColorScheme

  /// The current color scheme contrast in the environment.
  public var colorSchemeContrast: ColorSchemeContrast

  /// A smaller environment value set used for color resolution.
  public var colorEnvironment: ColorEnvironmentValues {
    .init(
      colorScheme: colorScheme,
      colorSchemeContrast: colorSchemeContrast
    )
  }

  init(
    font: Font? = nil,
    dynamicTypeSize: DynamicTypeSize = .large,
    legibilityWeight: LegibilityWeight? = nil,
    emojiProperties: EmojiProperties = .init(),
    mathProperties: MathProperties = .init(),
    colorScheme: ColorScheme = .light,
    colorSchemeContrast: ColorSchemeContrast = .standard
  ) {
    self.font = font
    self.dynamicTypeSize = dynamicTypeSize
    self.legibilityWeight = legibilityWeight
    self.emojiProperties = emojiProperties
    self.mathProperties = mathProperties
    self.colorScheme = colorScheme
    self.colorSchemeContrast = colorSchemeContrast
  }
}

extension EnvironmentValues {
  var textEnvironment: TextEnvironmentValues {
    .init(
      font: font,
      dynamicTypeSize: dynamicTypeSize,
      legibilityWeight: legibilityWeight,
      emojiProperties: emojiProperties,
      mathProperties: mathProperties,
      colorScheme: colorScheme,
      colorSchemeContrast: colorSchemeContrast
    )
  }
}
