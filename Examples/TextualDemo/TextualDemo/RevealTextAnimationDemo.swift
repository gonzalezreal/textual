import SwiftUI
import Textual

struct RevealTextAnimationDemo: View {
  @State private var visibleMarkdown = ""
  @State private var isStreaming = false
  @State private var streamTask: Task<Void, Never>?
  @State private var markdownBuffer = StreamingMarkdownBuffer()

  private let content = """
    # Why Streaming Text Feels Alive

    When an assistant's reply appears **word by word** instead of all at once, it reads less \
    like a database dump and more like *someone thinking out loud*. That small delay is doing \
    a lot of work.

    ## What Makes It Convincing

    A good reveal animation isn't just a typewriter effect. It usually blends a few techniques:

    - **Per-glyph clusters** so text doesn't feel mechanical
    - **Opacity and blur ramps** that let each fragment settle into place
    - A pace that adapts so it never falls behind what's actually arrived

    > The best reveal animations disappear. You stop noticing the animation and just feel like \
    you're watching someone type.

    ![A calm reading space](https://picsum.photos/seed/textual-reveal/400/200)

    ## Built on `TextRenderer`

    iOS 18's `TextRenderer` protocol lets Textual intercept how `Text` draws its glyphs and \
    apply custom effects per run, per glyph, or per line—without giving up SwiftUI's layout \
    engine.

    ```swift
    struct RevealTextRenderer: TextRenderer {
      func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
          for run in line {
            // Fade in each newly-revealed glyph cluster here.
          }
        }
      }
    }
    ```

    Tap **Start Animation** below to watch this whole page stream back in, one glyph cluster \
    at a time.
    """

  private static let bottomAnchorID = "bottom"

  var body: some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 0) {
            StructuredText(markdown: visibleMarkdown)
              .textual.textStreaming(isStreaming)
              .textual.revealAnimation(.default)
              .textual.textSelection(.enabled)
              .padding()

            // Invisible anchor that always sits just past the last streamed line, so scrolling
            // to it keeps the newest text in view as the response grows.
            Color.clear
              .frame(height: 1)
              .id(Self.bottomAnchorID)
          }
        }
        .onChange(of: visibleMarkdown) {
          withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(Self.bottomAnchorID, anchor: .bottom)
          }
        }
      }

      Divider()

      Button {
        startStreaming()
      } label: {
        Text(isStreaming ? "Streaming…" : "Start Animation")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .padding()
      .disabled(isStreaming)
    }
    .onDisappear {
      streamTask?.cancel()
    }
  }

  private func startStreaming() {
    streamTask?.cancel()
    markdownBuffer = StreamingMarkdownBuffer()
    visibleMarkdown = ""
    isStreaming = true

    streamTask = Task {
      for chunk in Self.simulatedServerChunks(of: content) {
        if Task.isCancelled { return }
        visibleMarkdown = markdownBuffer.append(chunk)
        try? await Task.sleep(for: .milliseconds(Int.random(in: 40...160)))
      }
      guard !Task.isCancelled else { return }
      visibleMarkdown = markdownBuffer.flush()
      isStreaming = false
    }
  }

  /// Splits `text` into randomly-sized chunks, simulating how a server might flush a streamed
  /// response in bursts. Chunk boundaries are deliberately unaligned with word or Markdown token
  /// boundaries — like real token streams — so they frequently land mid-construct (e.g. inside a
  /// `**bold**` span), exercising `StreamingMarkdownBuffer`.
  private static func simulatedServerChunks(of text: String) -> [String] {
    var chunks: [String] = []
    var remaining = Substring(text)

    while !remaining.isEmpty {
      let size = Int.random(in: 6...20)
      let end =
        remaining.index(remaining.startIndex, offsetBy: size, limitedBy: remaining.endIndex)
        ?? remaining.endIndex
      chunks.append(String(remaining[..<end]))
      remaining = remaining[end...]
    }

    return chunks
  }
}

#Preview {
  RevealTextAnimationDemo()
}
