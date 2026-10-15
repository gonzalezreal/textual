import SwiftUI

// MARK: - Overview
//
// `WithInlineStyle` applies an `InlineStyle` to an `AttributedString` before it reaches the
// rendering pipeline.
//
// The input `AttributedString` is expected to carry inline semantics using standard Foundation
// attributes:
// - `inlinePresentationIntent` identifies spans like code, emphasis, strong, and strikethrough.
// - `link` identifies URLs.
//
// The view reads `InlineStyle` and `TextEnvironmentValues` from the environment, then produces a
// styled copy of the attributed string by merging attributes into each matching span.
//
// Styling is recomputed whenever the input, style, or environment snapshot changes.

struct WithInlineStyle<Content: View>: View {
  @Environment(\.inlineStyle) private var style
  @Environment(\.textEnvironment) private var environment

  @State private var output = Memo<
    Tuple<AttributedString, InlineStyle, TextEnvironmentValues>, AttributedString
  >()

  private let input: AttributedString
  private let content: (AttributedString) -> Content

  init(
    _ input: AttributedString,
    @ViewBuilder content: @escaping (AttributedString) -> Content
  ) {
    self.input = input
    self.content = content
  }

  var body: some View {
    content(
      output.value(for: Tuple(input, style, environment)) {
        resolve(
          attributedString: $0.values.0,
          style: $0.values.1,
          in: $0.values.2
        )
      }
    )
  }

  private func resolve(
    attributedString: AttributedString,
    style: InlineStyle,
    in environment: TextEnvironmentValues
  ) -> AttributedString {
    var output = attributedString

    for run in attributedString.runs {
      var attributes = AttributeContainer()

      if let intent = run.inlinePresentationIntent {
        if intent.contains(.code) {
          style.code.apply(in: &attributes, environment: environment)
        }

        if intent.contains(.emphasized) {
          style.emphasis.apply(in: &attributes, environment: environment)
        }

        if intent.contains(.stronglyEmphasized) {
          style.strong.apply(in: &attributes, environment: environment)
        }

        if intent.contains(.strikethrough) {
          style.strikethrough.apply(in: &attributes, environment: environment)
        }
      }

      if run.link != nil {
        style.link.apply(in: &attributes, environment: environment)
      }

      output[run.range].mergeAttributes(attributes, mergePolicy: .keepNew)
    }

    return output
  }
}
