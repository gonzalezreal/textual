import Foundation

// MARK: - Overview
//
// `PatternProcessor` applies pattern-based substitutions to an `AttributedString` after parsing.
// It walks each run, skips preformatted content, tokenizes the run’s text, and replaces tokens
// using the first matching rule.
//
// The processor keeps run attributes intact for unchanged text and allows replacement rules to
// inject new attributes (for example, emoji URLs) while preserving the rest of the run’s metadata.
//
// Rules are opt-in; when no rules are provided, the input is returned unchanged.

struct PatternProcessor {
  private let rules: [Rule]
  private let tokenizer: PatternTokenizer

  init(rules: [Rule]) {
    self.rules = rules
    self.tokenizer = PatternTokenizer(patterns: rules.flatMap(\.patterns))
  }

  func expand(_ attributedString: AttributedString) throws -> AttributedString {
    guard !rules.isEmpty else {
      return attributedString
    }

    var output = AttributedString()

    for run in attributedString.runs {
      if run.isPreformatted {
        output.append(attributedString[run.range])
      } else {
        let text = String(attributedString[run.range].characters[...])
        let tokens = try tokenizer.tokenize(text)

        if tokens.count == 1, tokens.first?.type == .text {
          // There are no patterns detected
          output.append(attributedString[run.range])
        } else {
          for token in tokens {
            if let rule = rules.firstMatching(token.type),
              let replacement = rule.replace(token, run.attributes)
            {
              output.append(replacement)
            } else {
              // Append the token content without replacing
              output.append(AttributedString(token.content, attributes: run.attributes))
            }
          }
        }
      }
    }

    return output
  }
}

extension PatternProcessor {
  struct Rule {
    let patterns: [PatternTokenizer.Pattern]
    let replace:
      (
        _ token: PatternTokenizer.Token,
        _ attributes: AttributeContainer
      ) -> AttributedString?
  }
}

extension PatternProcessor.Rule {
  static func emoji(_ emoji: Set<Emoji>) -> Self {
    guard !emoji.isEmpty else {
      return Self(patterns: [], replace: { _, _ in nil })
    }

    let emojiMap = Dictionary(
      uniqueKeysWithValues: emoji.map { emoji in
        (emoji.shortcode, emoji)
      }
    )

    return Self(patterns: [.emoji]) { token, attributes in
      guard let shortcode = token.capturedContent, let emoji = emojiMap[shortcode] else {
        return nil
      }

      return AttributedString(
        shortcode,
        attributes: attributes.emojiURL(emoji.url)
      )
    }
  }

  static var math: Self {
    .init(patterns: [.mathBlock, .mathInline]) { token, attributes in
      guard let latex = token.capturedContent else {
        return nil
      }

      let attachment = MathAttachment(
        latex: latex,
        style: token.type == .mathBlock ? .block : .inline
      )
      return AttributedString("\u{FFFC}", attributes: attributes.attachment(.init(attachment)))
    }
  }
}

extension Array where Element == PatternProcessor.Rule {
  func firstMatching(_ tokenType: PatternTokenizer.TokenType) -> Element? {
    guard tokenType != .text else {
      return nil
    }
    return first { rule in
      rule.patterns.map(\.tokenType).contains(tokenType)
    }
  }
}

extension AttributedString.Runs.Run {
  fileprivate var isPreformatted: Bool {
    if self.inlinePresentationIntent?.isPreformatted ?? false {
      return true
    }

    if self.presentationIntent?.isPreformatted ?? false {
      return true
    }

    return false
  }
}

extension InlinePresentationIntent {
  fileprivate var isPreformatted: Bool {
    contains(.code) || contains(.inlineHTML) || contains(.blockHTML)
  }
}

extension PresentationIntent {
  fileprivate var isPreformatted: Bool {
    components.first?.kind.isPreformatted ?? false
  }
}

extension PresentationIntent.Kind {
  fileprivate var isPreformatted: Bool {
    switch self {
    case .codeBlock:
      return true
    default:
      return false
    }
  }
}
