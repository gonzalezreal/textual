import SwiftUI
import Testing

@testable import Textual

struct TextPropertyTests {
  @Test(
    arguments: [
      (
        AnyTextProperty(.foregroundColor(.red)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().foregroundColor(.red)
      ),
      (
        AnyTextProperty(.backgroundColor(.red)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().backgroundColor(.red)
      ),
      (
        AnyTextProperty(.strikethroughStyle(.single)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().strikethroughStyle(.single)
      ),
      (
        AnyTextProperty(.underlineStyle(.single)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().underlineStyle(.single)
      ),
      (
        AnyTextProperty(.kerning(-0.1)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().kern(-0.1)
      ),
      (
        AnyTextProperty(.tracking(-0.1)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().tracking(-0.1)
      ),
      (
        AnyTextProperty(.baselineOffset(5)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().baselineOffset(5)
      ),
      (
        AnyTextProperty(.font(.body)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body)
      ),
      (
        AnyTextProperty(.bold),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.bold())
      ),
      (
        AnyTextProperty(.bold),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.bold())
      ),
      (
        AnyTextProperty(.bold),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.bold())
      ),
      (
        AnyTextProperty(.italic),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.italic())
      ),
      (
        AnyTextProperty(.italic),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.italic())
      ),
      (
        AnyTextProperty(.italic),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.italic())
      ),
      (
        AnyTextProperty(.monospaced),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.monospaced())
      ),
      (
        AnyTextProperty(.monospaced),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.monospaced())
      ),
      (
        AnyTextProperty(.monospaced),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.monospaced())
      ),
      (
        AnyTextProperty(.monospacedDigit),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.monospacedDigit())
      ),
      (
        AnyTextProperty(.monospacedDigit),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.monospacedDigit())
      ),
      (
        AnyTextProperty(.monospacedDigit),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.monospacedDigit())
      ),
      (
        AnyTextProperty(.smallCaps),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.smallCaps())
      ),
      (
        AnyTextProperty(.smallCaps),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.smallCaps())
      ),
      (
        AnyTextProperty(.smallCaps),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.smallCaps())
      ),
      (
        AnyTextProperty(.fontWeight(.medium)),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.weight(.medium))
      ),
      (
        AnyTextProperty(.fontWeight(.medium)),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.weight(.medium))
      ),
      (
        AnyTextProperty(.fontWeight(.medium)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.weight(.medium))
      ),
      (
        AnyTextProperty(.fontWidth(.compressed)),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.width(.compressed))
      ),
      (
        AnyTextProperty(.fontWidth(.compressed)),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.width(.compressed))
      ),
      (
        AnyTextProperty(.fontWidth(.compressed)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.width(.compressed))
      ),
      (
        AnyTextProperty(.fontLeading(.loose)),
        AttributeContainer().font(.caption),
        TextEnvironmentValues(),
        AttributeContainer().font(.caption.leading(.loose))
      ),
      (
        AnyTextProperty(.fontLeading(.loose)),
        AttributeContainer(),
        TextEnvironmentValues(font: .title),
        AttributeContainer().font(.title.leading(.loose))
      ),
      (
        AnyTextProperty(.fontLeading(.loose)),
        AttributeContainer(),
        TextEnvironmentValues(),
        AttributeContainer().font(.body.leading(.loose))
      ),
      (
        AnyTextProperty(.fontScale(0.5)),
        AttributeContainer().font(.system(size: 16)),
        TextEnvironmentValues(),
        AttributeContainer().font(.system(size: 16, scale: 0.5))
      ),
      (
        AnyTextProperty(.fontScale(0.5)),
        AttributeContainer(),
        TextEnvironmentValues(font: .system(size: 14)),
        AttributeContainer().font(.system(size: 14, scale: 0.5))
      ),
    ]
  )
  func textProperty(
    _ property: AnyTextProperty,
    attributes: AttributeContainer,
    environment: TextEnvironmentValues,
    expected: AttributeContainer
  ) {
    var result = attributes
    property.apply(in: &result, environment: environment)
    #expect(result == expected)
  }
}

extension Font {
  fileprivate static func system(size: CGFloat, scale: CGFloat) -> Font {
    #if compiler(>=6.2)
      if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        .system(size: size).scaled(by: scale)
      } else {
        .system(size: size * scale)
      }
    #else
      .system(size: size * scale)
    #endif
  }
}
