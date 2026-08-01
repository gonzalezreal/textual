import SwiftUI
import Textual

struct RevealTextAnimationDemo: View {
  @State private var isAnimating = false

  private let content = """
    # Why Streaming Text Feels Alive

    When an assistant's reply appears **word by word** instead of all at once, it reads less \
    like a database dump and more like *someone thinking out loud*. That small delay is doing \
    a lot of work.

    ## What Makes It Convincing

    A good reveal animation isn't just a typewriter effect. It usually blends a few techniques:

    - **Per-glyph or per-word timing** so text doesn't feel mechanical
    - **Opacity and blur ramps** that let each fragment settle into place
    - A slight **variance in pacing** so it doesn't feel like a metronome

    > The best reveal animations disappear. You stop noticing the animation and just feel like \
    you're watching someone type.

    ## Built on `TextRenderer`

    iOS 18 introduced the `TextRenderer` protocol, which lets us intercept how `Text` draws its \
    glyphs and apply custom effects per run, per glyph, or per line—without giving up SwiftUI's \
    layout engine.

    ```swift
    struct RevealTextRenderer: TextRenderer {
      func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
          for run in line {
            // Animate each run's opacity, blur, or offset here.
          }
        }
      }
    }
    ```

    Press **Start Animation** below once this is wired up, and this paragraph will reveal \
    itself the same way.
    """

  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        StructuredText(markdown: content)
          .textual.textSelection(.enabled)
          .padding()
      }

      Divider()

      Button {
        isAnimating.toggle()
      } label: {
        Text("Start Animation")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .padding()
    }
  }
}

#Preview {
  RevealTextAnimationDemo()
}
