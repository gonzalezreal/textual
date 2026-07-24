import SwiftUI
import Textual

struct PostprocessorDemo: View {
  @State private var query = "text"

  var body: some View {
    Form {
      Section("Search Highlighter") {
        TextField("Search", text: $query)
      }

      Section("Inline Text") {
        InlineText(
          markdown: """
            Textual renders **rich attributed text** in SwiftUI. Use a postprocessor \
            to highlight ranges independently of the markup content.
            """
        )
        .textual.attributedStringPostprocessor(SearchHighlighter(query: query))
        .textual.textSelection(.enabled)
      }

      Section("Structured Text") {
        StructuredText(
          markdown: """
            ## Overview

            A postprocessor runs **after parsing and attachment resolution**, so it can
            add attributes whose source is external to the text — for example, a
            live search query.

            - Highlights update without re-parsing
            - Ranges are valid against the full attributed string
            """
        )
        .textual.attributedStringPostprocessor(SearchHighlighter(query: query))
        .textual.textSelection(.enabled)
      }
    }
    .formStyle(.grouped)
  }
}

private struct SearchHighlighter: AttributedStringPostprocessor {
  let query: String

  func postprocess(input: AttributedString) -> AttributedString {
    guard !query.isEmpty else {
      return input
    }

    var output = input
    var start = output.startIndex

    while let range = output[start...].range(of: query, options: .caseInsensitive) {
      output[range].backgroundColor = .yellow.opacity(0.4)
      start = range.upperBound
    }

    return output
  }
}

#Preview {
  PostprocessorDemo()
}
