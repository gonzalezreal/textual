import SwiftUI

// MARK: - Overview
//
// `WithAttributedStringPostprocessor` applies an `AttributedStringPostprocessor` from the
// environment to an `AttributedString` before it reaches the rendering pipeline.
//
// The view reads `attributedStringPostprocessor` from the environment, then produces a processed
// copy of the attributed string by calling `postprocess(input:)`.
//
// Processing is recomputed whenever the input or the postprocessor changes.

struct WithAttributedStringPostprocessor<Content: View>: View {
  @Environment(\.attributedStringPostprocessor) private var attributedStringPostprocessor

  @State private var output: AttributedString?

  let attributedString: AttributedString
  let content: (AttributedString) -> Content

  var body: some View {
    content(output ?? AttributedString())
      .onChange(of: Tuple(attributedString, attributedStringPostprocessor), initial: true) {
        output = attributedStringPostprocessor.postprocess(input: attributedString)
      }
  }

  init(
    _ attributedString: AttributedString,
    @ViewBuilder content: @escaping (AttributedString) -> Content
  ) {
    self.attributedString = attributedString
    self.content = content
  }
}
