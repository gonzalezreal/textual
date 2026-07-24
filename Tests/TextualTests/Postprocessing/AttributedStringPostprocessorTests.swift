import SwiftUI
import Testing

@testable import Textual

struct AttributedStringPostprocessorTests {
  @Test func typeErasedBoxEquality() {
    let a = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "world"))
    let b = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "world"))
    let c = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "Hello"))

    #expect(a == b)
    #expect(a != c)
  }

  @Test func typeErasedBoxHashability() {
    let a = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "world"))
    let b = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "world"))
    let c = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "Hello"))

    #expect(a.hashValue == b.hashValue)
    #expect(a.hashValue != c.hashValue)
  }

  @Test func typeErasedBoxDelegatesToBase() {
    let box = AnyAttributedStringPostprocessor(Fixtures.SearchHighlighter(query: "world"))
    let input = AttributedString("Hello, world")
    let output = box.postprocess(input: input)

    let highlightedRanges = output.runs.compactMap { run -> Range<AttributedString.Index>? in
      run.backgroundColor != nil ? run.range : nil
    }

    #expect(highlightedRanges.count == 1)
    #expect(String(input[highlightedRanges[0]].characters) == "world")
  }
}

private enum Fixtures {
  struct SearchHighlighter: AttributedStringPostprocessor {
    let query: String

    func postprocess(input: AttributedString) -> AttributedString {
      var output = input
      var start = output.startIndex

      while let range = output[start...].range(of: query, options: .caseInsensitive) {
        output[range].backgroundColor = .yellow
        start = range.upperBound
      }

      return output
    }
  }
}
