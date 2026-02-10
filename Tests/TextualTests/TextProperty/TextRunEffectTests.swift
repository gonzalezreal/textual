import SwiftUI
import Testing

@testable import Textual

// MARK: - Test Effect

/// A simple test effect for unit testing.
private struct TestEffect: TextRunEffect {
  var value: CGFloat

  var animatableData: CGFloat {
    get { value }
    set { value = newValue }
  }

  func draw(run: Text.Layout.Run, in context: inout GraphicsContext) {
    // No-op for testing
  }
}

struct TextRunEffectTests {
  @Test func effectPropertyAppliesAttribute() {
    let effect = TestEffect(value: 0.5)
    let property = EffectProperty(effect)

    var attributes = AttributeContainer()
    property.apply(in: &attributes, environment: TextEnvironmentValues())

    #expect(attributes.textualEffect != nil)
  }

  @Test func effectAnimatableData() {
    var effect = TestEffect(value: 0.0)

    #expect(effect.animatableData == 0.0)

    effect.animatableData = 0.75
    #expect(effect.value == 0.75)
  }

  @Test func effectEquality() {
    let effect1 = TestEffect(value: 1.0)
    let effect2 = TestEffect(value: 1.0)
    let effect3 = TestEffect(value: 0.5)

    #expect(effect1 == effect2)
    #expect(effect1 != effect3)
  }

  @Test func anyTextRunEffectWrapsEffect() {
    let effect = TestEffect(value: 1.0)
    let anyEffect1 = AnyTextRunEffect(effect)
    let anyEffect2 = AnyTextRunEffect(effect)

    #expect(anyEffect1 == anyEffect2)
  }

  @Test func anyTextRunEffectInequality() {
    let effect1 = TestEffect(value: 1.0)
    let effect2 = TestEffect(value: 0.5)
    let anyEffect1 = AnyTextRunEffect(effect1)
    let anyEffect2 = AnyTextRunEffect(effect2)

    #expect(anyEffect1 != anyEffect2)
  }

  @Test func effectPropertyEquality() {
    let effect1 = TestEffect(value: 1.0)
    let effect2 = TestEffect(value: 1.0)
    let effect3 = TestEffect(value: 0.5)

    let property1 = EffectProperty(effect1)
    let property2 = EffectProperty(effect2)
    let property3 = EffectProperty(effect3)

    #expect(property1 == property2)
    #expect(property1 != property3)
  }

  @Test func animatableEffectMarkerReturnsMarkerID() {
    let marker = AnimatableEffectMarker<TestEffect>()
    let anyEffect = AnyTextRunEffect(marker)

    // markerID uses String(reflecting:) which includes the full module path
    let markerID = anyEffect.animatableEffectMarkerID
    #expect(markerID != nil)
    #expect(markerID?.contains("TestEffect") == true)
  }

  @Test func regularEffectReturnsNilMarkerID() {
    let effect = TestEffect(value: 1.0)
    let anyEffect = AnyTextRunEffect(effect)

    #expect(anyEffect.animatableEffectMarkerID == nil)
  }

  @Test func attributedStringHasTextEffect() {
    let effect = TestEffect(value: 1.0)

    // String without effect
    let plainString = AttributedString("Hello")
    #expect(plainString.hasTextEffect == false)

    // String with effect
    var container = AttributeContainer()
    container.textualEffect = AnyTextRunEffect(effect)
    let styledString = AttributedString("World", attributes: container)
    #expect(styledString.hasTextEffect == true)

    // Combined string
    var combined = plainString
    combined.append(styledString)
    #expect(combined.hasTextEffect == true)
  }
}
