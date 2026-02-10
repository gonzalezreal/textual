import SwiftUI

// MARK: - Overview
//
// `TextualTextRenderer` is the core text renderer for Textual. It handles:
//
// 1. Drawing animatable effects (from environment, when provided)
// 2. Drawing static `TextRunEffect` effects
// 3. Drawing the text itself
//
// The renderer integrates with SwiftUI's `TextRenderer` protocol (iOS 18+/macOS 15+)
// to provide a unified rendering pipeline that supports both standard text attributes
// and custom drawing effects.
//
// Static effects are applied through the `TextProperty` system and stored in the
// `AttributeContainer`. Animatable effects are passed through the environment
// and provided to this renderer by `TextFragment`.

struct TextualTextRenderer: TextRenderer {
  var animatableEffect: AnyAnimatableEffect?

  init(animatableEffect: AnyAnimatableEffect? = nil) {
    self.animatableEffect = animatableEffect
  }

  func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
    // 1. Draw run effects (behind text)
    drawRunEffects(layout: layout, in: &ctx)

    // 2. Draw each line and run
    for line in layout {
      for run in line {
        ctx.draw(run)
      }
    }
  }

  /// Draws custom effects for runs that have effect attributes.
  private func drawRunEffects(layout: Text.Layout, in ctx: inout GraphicsContext) {
    for line in layout {
      for run in line {
        // Check for animatable effect marker first
        if let marker = run[AnimatableEffectMarkerAttribute.self],
           let effect = animatableEffect,
           marker.effectTypeID == effect.markerID {
          effect.draw(run: run, in: &ctx)
        }
        // Fall back to static effects
        else if let effect = run.textEffect {
          effect.draw(run: run, in: &ctx)
        }
      }
    }
  }
}
