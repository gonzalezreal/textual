import SwiftUI

// MARK: - Overview
//
// HighlightedTextFragment displays syntax-highlighted code using a two-phase approach.
// Tokenization runs asynchronously and is keyed by content, while highlighting runs
// synchronously on token or environment changes (theme, color scheme, dynamic type).
//
// The presentationIntent is preserved after highlighting so pasteboard formatters can
// reconstruct the block structure when copying code.

struct HighlightedTextFragment: View {
  @Environment(\.textEnvironment) private var textEnvironment

  @State private var model = Model()

  private let content: AttributedSubstring
  private let languageHint: String?
  private let theme: StructuredText.HighlighterTheme

  init(
    _ content: AttributedSubstring,
    languageHint: String?,
    theme: StructuredText.HighlighterTheme
  ) {
    self.content = content
    self.languageHint = languageHint
    self.theme = theme
  }

  var body: some View {
    TextFragment(model.highlightedCode ?? AttributedString(content))
      .foregroundStyle(theme.foregroundColor)
      .task(id: content) {
        await model.tokenize(
          content: content,
          languageHint: languageHint
        )
      }
      .onChange(of: Tuple(model.tokens, textEnvironment)) { _, newValue in
        model.highlight(
          tokens: newValue.values.0,
          original: content,
          presentationIntent: content.presentationIntent,
          using: theme,
          environment: newValue.values.1
        )
      }
  }
}

extension HighlightedTextFragment {
  @MainActor @Observable final class Model {
    var tokens: [CodeToken] = []
    var highlightedCode: AttributedString?

    func tokenize(content: AttributedSubstring, languageHint: String?) async {
      let code = String(content.characters[...])
      tokens = [CodeToken(content: code, type: .plain)]

      if let tokenizer = CodeTokenizer.shared, let languageHint {
        tokens = await tokenizer.tokenize(code: code, language: languageHint)
      }
    }

    func highlight(
      tokens: [CodeToken],
      original: AttributedSubstring,
      presentationIntent: PresentationIntent?,
      using theme: StructuredText.HighlighterTheme,
      environment: TextEnvironmentValues
    ) {
      var attributes = AttributeContainer()
      // Re-apply the presentation intent for pasteboard formatters
      attributes.presentationIntent = presentationIntent
      ForegroundColorProperty(theme.foregroundColor)
        .apply(in: &attributes, environment: environment)
      var highlightedCode = AttributedString()

      // Walk the ORIGINAL attributed content in parallel with the tokens and
      // slice it, rather than rebuilding each token from its plain String.
      // Rebuilding discards every attribute the caller's `MarkupParser` applied
      // before it can reach the screen. Theme attributes are merged on top, so
      // syntax colouring still wins for the keys it sets while caller attributes
      // survive for the rest.
      let total = original.characters.count
      var consumed = 0

      for token in tokens {
        var tokenAttributes = attributes

        if let tokenProperties = theme.tokenProperties[token.type] {
          tokenProperties.apply(in: &tokenAttributes, environment: environment)
        }

        let length = token.content.count
        var content: AttributedString
        if consumed + length <= total {
          let lower = original.index(original.startIndex, offsetByCharacters: consumed)
          let upper = original.index(original.startIndex, offsetByCharacters: consumed + length)
          content = AttributedString(original[lower..<upper])
        } else {
          // Tokenizer disagreed with the source length; fall back to the plain
          // token so text is never lost, accepting the attribute loss.
          content = AttributedString(token.content)
        }
        consumed += length

        content.mergeAttributes(tokenAttributes)
        highlightedCode.append(content)
      }

      self.highlightedCode = highlightedCode
    }
  }
}
