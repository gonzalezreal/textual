#if os(iOS)
  import SnapshotTesting
  import SwiftUI
  import Testing

  import Textual

  extension StructuredText {
    @MainActor
    struct MathExpressionTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func inlineAndBlockMath() {
        let view = StructuredText(
          markdown: """
            Inline math feels natural: $E = mc^2$.

            $$\\int_{0}^{1} x^2\\,dx = \\frac{1}{3}$$

            ```math
            \\left( a + b \\right)^2 = a^2 + 2ab + b^2
            ```
            """,
          patternOptions: .init(processesMathExpressions: true)
        )
        .background(Color.guide)
        .padding(.horizontal)

        assertSnapshot(of: view, as: .image(layout: layout))
      }

      @Test func mathBlockAlignment() {
        let view = StructuredText(
          markdown: """
            Leading paragraph for context.

            $$a^2 + b^2 = c^2$$

            Trailing paragraph for context.
            """,
          patternOptions: .init(processesMathExpressions: true)
        )
        .padding(.horizontal)
        .multilineTextAlignment(.leading)
        .textual.mathProperties(.init(textAlignment: .trailing))

        assertSnapshot(of: view, as: .image(layout: layout))
      }
    }
  }
#endif
