import SwiftUI
import Testing

@testable import Textual

@MainActor
struct HighlightedTextFragmentTests {
  private let environment = TextEnvironmentValues()

  /// Builds the `AttributedSubstring` a code block receives, with `background`
  /// applied over `highlightedRange` the way a client's `MarkupParser` would.
  private func content(
    _ text: String,
    background: Color? = nil,
    over highlightedRange: Range<Int>? = nil
  ) -> AttributedSubstring {
    var attributed = AttributedString(text)
    if let background, let highlightedRange {
      let lower = attributed.index(
        attributed.startIndex, offsetByCharacters: highlightedRange.lowerBound)
      let upper = attributed.index(
        attributed.startIndex, offsetByCharacters: highlightedRange.upperBound)
      attributed[lower..<upper].backgroundColor = background
    }
    return attributed[attributed.startIndex..<attributed.endIndex]
  }

  private func highlighted(
    _ text: String,
    tokens: [CodeToken],
    background: Color? = nil,
    over highlightedRange: Range<Int>? = nil,
    theme: StructuredText.HighlighterTheme = .default
  ) -> AttributedString {
    let model = HighlightedTextFragment.Model()
    model.highlight(
      tokens: tokens,
      original: content(text, background: background, over: highlightedRange),
      presentationIntent: nil,
      using: theme,
      environment: environment
    )
    return model.highlightedCode ?? AttributedString()
  }

  @Test func preservesCallerAttributesOnCodeBlockContent() {
    let result = highlighted(
      "let secret = 1",
      tokens: [CodeToken(content: "let secret = 1", type: .plain)],
      background: .yellow,
      over: 4..<10
    )

    let marked = result.runs
      .filter { $0.backgroundColor == .yellow }
      .map { String(result[$0.range].characters) }

    #expect(marked == ["secret"])
  }

  /// The attribute has to survive being split across token boundaries too — the
  /// tokenizer knows nothing about the caller's ranges.
  @Test func preservesCallerAttributesAcrossTokenBoundaries() {
    let result = highlighted(
      "let secret = 1",
      tokens: [
        CodeToken(content: "let ", type: .keyword),
        CodeToken(content: "secret", type: .plain),
        CodeToken(content: " = 1", type: .plain),
      ],
      background: .yellow,
      over: 4..<10
    )

    let marked = result.runs
      .filter { $0.backgroundColor == .yellow }
      .map { String(result[$0.range].characters) }

    #expect(marked == ["secret"])
  }

  @Test func textIsUnchangedWhenTheCallerAppliesNoAttributes() {
    let result = highlighted(
      "let secret = 1",
      tokens: [CodeToken(content: "let secret = 1", type: .plain)]
    )

    #expect(String(result.characters) == "let secret = 1")
    #expect(result.runs.allSatisfy { $0.backgroundColor == nil })
  }

  /// Theme token properties are merged on top, so syntax colouring still wins
  /// for the keys it sets while caller attributes survive for the rest.
  @Test func themeStillStylesTokens() {
    let theme = StructuredText.HighlighterTheme(
      foregroundColor: .init(light: .black, dark: .white),
      backgroundColor: .init(light: .white, dark: .black),
      tokenProperties: [
        .keyword: AnyTextProperty(ForegroundColorProperty(.init(light: .red, dark: .red)))
      ]
    )

    let result = highlighted(
      "let secret = 1",
      tokens: [
        CodeToken(content: "let ", type: .keyword),
        CodeToken(content: "secret = 1", type: .plain),
      ],
      background: .yellow,
      over: 4..<10,
      theme: theme
    )

    // The caller's background survived...
    #expect(result.runs.contains { $0.backgroundColor == .yellow })
    // ...and the theme still coloured the keyword.
    #expect(result.runs.contains { $0.foregroundColor == .red })
  }

  /// If the tokenizer's total length disagrees with the source, the extra token
  /// falls back to its plain string so text is never lost.
  @Test func fallsBackToPlainTokenWhenLengthsDisagree() {
    let result = highlighted(
      "abc",
      tokens: [
        CodeToken(content: "abc", type: .plain),
        CodeToken(content: "extra", type: .plain),
      ]
    )

    #expect(String(result.characters) == "abcextra")
  }
}
