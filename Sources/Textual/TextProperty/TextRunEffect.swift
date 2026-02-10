import SwiftUI

// MARK: - Overview
//
// `TextRunEffect` defines a custom drawing effect that can be applied to text runs.
//
// Unlike standard text properties that modify `AttributeContainer`, effects provide
// full control over rendering via `GraphicsContext`. This enables advanced visual
// treatments like animated highlights, custom underlines, or gradient backgrounds
// that aren't possible with standard text attributes.
//
// Effects are applied through the `TextProperty` system using `.effect(_:)` and
// rendered by `TextualTextRenderer` during the text drawing phase.

/// A custom drawing effect for text runs.
///
/// Conform to `TextRunEffect` to create custom visual treatments for inline text.
/// Effects have full access to `GraphicsContext` and can draw before or after the text.
///
/// ## Basic Usage
///
/// ```swift
/// struct HighlightEffect: TextRunEffect {
///   var color: Color
///
///   func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
///     let bounds = run.typographicBounds.rect
///     context.fill(Path(bounds), with: .color(color.opacity(0.3)))
///   }
/// }
/// ```
///
/// ## Animation
///
/// To animate effect properties, implement `animatableData` and use
/// `AnimatableEffectMarker` with the `.textual.animatableEffect()` modifier:
///
/// ```swift
/// struct AnimatedHighlightEffect: TextRunEffect {
///   var progress: CGFloat
///
///   var animatableData: CGFloat {
///     get { progress }
///     set { progress = newValue }
///   }
///
///   func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
///     let bounds = run.typographicBounds.rect
///     let width = bounds.width * progress
///     context.fill(Path(CGRect(x: bounds.minX, y: bounds.minY, width: width, height: bounds.height)),
///                  with: .color(.yellow.opacity(0.3)))
///   }
/// }
///
/// // In your view:
/// @State var progress: CGFloat = 0
///
/// InlineText(markdown: "**Important text**")
///   .textual.inlineStyle(
///     InlineStyle().strong(EffectProperty(AnimatableEffectMarker<AnimatedHighlightEffect>()))
///   )
///   .textual.animatableEffect(AnimatedHighlightEffect(progress: progress))
///   .onAppear {
///     withAnimation(.easeInOut(duration: 1)) { progress = 1 }
///   }
/// ```
public protocol TextRunEffect: Sendable, Hashable {
  /// The type of animatable data for this effect.
  associatedtype AnimatableData: VectorArithmetic = EmptyAnimatableData

  /// The animatable data for this effect.
  ///
  /// Implement this property to enable smooth animations when effect properties change.
  var animatableData: AnimatableData { get set }

  /// Draws the effect for the given text run.
  ///
  /// This method is called by the text renderer for each run that has this effect applied.
  /// Draw behind the text by calling this before `context.draw(layout)`, or draw on top
  /// by calling it after.
  ///
  /// - Parameters:
  ///   - run: The text run to draw the effect for.
  ///   - context: The graphics context to draw into.
  func draw(run: Text.Layout.Run, in context: inout GraphicsContext)
}

extension TextRunEffect where AnimatableData == EmptyAnimatableData {
  public var animatableData: EmptyAnimatableData {
    get { EmptyAnimatableData() }
    set {}
  }
}

/// A type-erased wrapper for `TextRunEffect`.
public struct AnyTextRunEffect: Sendable, Hashable {
  private let box: any EffectBox

  /// Creates a type-erased wrapper around a concrete effect.
  public init<Effect: TextRunEffect>(_ effect: Effect) {
    self.box = ConcreteEffectBox(effect)
  }

  func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
    box.draw(run: run, in: &context)
  }

  /// Returns the marker ID if this is an animatable effect marker, nil otherwise.
  var animatableEffectMarkerID: String? {
    box.animatableEffectMarkerID
  }

  public static func == (lhs: AnyTextRunEffect, rhs: AnyTextRunEffect) -> Bool {
    lhs.box.isEqual(to: rhs.box)
  }

  public func hash(into hasher: inout Hasher) {
    box.hash(into: &hasher)
  }
}

// MARK: - Effect Box Protocol

private protocol EffectBox: Sendable {
  func draw(run: Text.Layout.Run, in context: inout GraphicsContext)
  func isEqual(to other: any EffectBox) -> Bool
  func hash(into hasher: inout Hasher)
  var animatableEffectMarkerID: String? { get }
}

private struct ConcreteEffectBox<Effect: TextRunEffect>: EffectBox {
  var effect: Effect

  init(_ effect: Effect) {
    self.effect = effect
  }

  func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
    effect.draw(run: run, in: &context)
  }

  func isEqual(to other: any EffectBox) -> Bool {
    guard let other = other as? ConcreteEffectBox<Effect> else { return false }
    return effect == other.effect
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(effect)
  }

  var animatableEffectMarkerID: String? {
    (effect as? any AnimatableEffectMarkerProtocol)?.effectTypeID
  }
}

/// Protocol to identify AnimatableEffectMarker types.
protocol AnimatableEffectMarkerProtocol {
  var effectTypeID: String { get }
}
