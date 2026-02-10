import SwiftUI

// MARK: - Overview
//
// This file provides SwiftUI animation support for text effects through
// `AnimatableEffectMarker` and `AnimatableEffectModifier`.
//
// The key insight is that effects stored in AttributeContainer cannot participate
// in SwiftUI's animation system due to type erasure. This is solved by:
//
// 1. Using `AnimatableEffectMarker<Effect>` as a placeholder in InlineStyle
// 2. Passing the actual effect through the environment via `.textual.animatableEffect()`
// 3. Having `TextFragment` read the effect and pass it to `TextualTextRenderer`
//
// The `AnimatableEffectModifier` conforms to `Animatable`, enabling SwiftUI to
// interpolate the effect's `animatableData` during animations.

// MARK: - Environment Key for Animatable Effects

extension EnvironmentValues {
  @Entry var animatableEffect: AnyAnimatableEffect? = nil
}

// MARK: - Type-Erased Animatable Effect

/// A type-erased wrapper for animatable effects that can be stored in environment.
struct AnyAnimatableEffect {
  private let _markerID: String
  private let _draw: (Text.Layout.Run, inout GraphicsContext) -> Void

  init<Effect: TextRunEffect>(_ effect: Effect) {
    self._markerID = AnimatableEffectMarker<Effect>.markerID
    self._draw = { run, context in
      effect.draw(run: run, in: &context)
    }
  }

  var markerID: String { _markerID }

  func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
    _draw(run, &context)
  }
}

// MARK: - Animatable Effect Marker

/// A marker attribute that indicates a run should use an animatable effect.
struct AnimatableEffectMarkerAttribute: TextAttribute {
  let effectTypeID: String
}

/// A marker effect that indicates a run should use an animatable effect.
///
/// Use this as a placeholder in `InlineStyle` when you want to animate
/// the actual effect through the `.textual.animatableEffect()` modifier.
///
/// ```swift
/// InlineText(markdown: "**Bold text**")
///   .textual.inlineStyle(
///     InlineStyle().strong(EffectProperty(AnimatableEffectMarker<HighlightEffect>()))
///   )
///   .textual.animatableEffect(HighlightEffect(progress: progress))
/// ```
public struct AnimatableEffectMarker<Effect: TextRunEffect>: TextRunEffect {
  static var markerID: String {
    String(reflecting: Effect.self)
  }

  public init() {}

  public func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
    // No-op - the actual drawing is done by TextualTextRenderer using the environment effect
  }
}

// Internal conformance to AnimatableEffectMarkerProtocol
extension AnimatableEffectMarker: AnimatableEffectMarkerProtocol {
  var effectTypeID: String {
    Self.markerID
  }
}

// MARK: - View Modifier

/// A view modifier that provides an animatable effect through the environment.
struct AnimatableEffectModifier<Effect: TextRunEffect>: ViewModifier, @MainActor Animatable {
  var effect: Effect

  var animatableData: Effect.AnimatableData {
    get { effect.animatableData }
    set { effect.animatableData = newValue }
  }

  func body(content: Content) -> some View {
    content.environment(\.animatableEffect, AnyAnimatableEffect(effect))
  }
}

// MARK: - View Extension

extension TextualNamespace where Base: View {
  /// Applies an animatable text effect to the view.
  ///
  /// Use this modifier in combination with `AnimatableEffectMarker` to enable
  /// SwiftUI animations for text effects:
  ///
  /// ```swift
  /// @State private var progress: CGFloat = 0
  ///
  /// InlineText(markdown: "**Animated text**")
  ///   .textual.inlineStyle(
  ///     InlineStyle().strong(EffectProperty(AnimatableEffectMarker<HighlightEffect>()))
  ///   )
  ///   .textual.animatableEffect(HighlightEffect(progress: progress))
  ///   .onAppear {
  ///     withAnimation(.easeInOut(duration: 1)) {
  ///       progress = 1
  ///     }
  ///   }
  /// ```
  ///
  /// - Parameter effect: The effect to apply and animate.
  /// - Returns: A view with the animatable effect applied.
  @MainActor
  public func animatableEffect<Effect: TextRunEffect>(_ effect: Effect) -> some View {
    base.modifier(AnimatableEffectModifier(effect: effect))
  }
}
