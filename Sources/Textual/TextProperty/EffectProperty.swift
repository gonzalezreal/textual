import SwiftUI

// MARK: - Overview
//
// `EffectProperty` wraps a `TextRunEffect` as a `TextProperty`, enabling custom
// drawing effects to be used within the `InlineStyle` system.
//
// When applied, the effect is stored in the `AttributeContainer` so that
// `TextualTextRenderer` can later retrieve and execute it during rendering.

/// A text property that applies a custom drawing effect.
///
/// Use `EffectProperty` to wrap a `TextRunEffect` for use with `InlineStyle`:
///
/// ```swift
/// InlineText(markdown: "This is **highlighted** text")
///   .textual.inlineStyle(
///     InlineStyle()
///       .strong(.effect(HighlightEffect(color: .yellow)))
///   )
/// ```
public struct EffectProperty<Effect: TextRunEffect>: TextProperty {
  private let effect: Effect

  /// Creates an effect property with the given effect.
  public init(_ effect: Effect) {
    self.effect = effect
  }

  public func apply(in attributes: inout AttributeContainer, environment: TextEnvironmentValues) {
    attributes.textualEffect = AnyTextRunEffect(effect)
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.effect == rhs.effect
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(effect)
  }
}

extension AnyTextProperty {
  /// Creates a text property that applies a custom drawing effect.
  ///
  /// - Parameter effect: The effect to apply.
  /// - Returns: A text property that applies the effect.
  public static func effect<E: TextRunEffect>(_ effect: E) -> AnyTextProperty {
    AnyTextProperty(EffectProperty(effect))
  }
}
