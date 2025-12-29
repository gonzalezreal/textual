import Foundation

// MARK: - Overview
//
// `MarkupTokenizer` scans markup source text and splits it into tokens based on a small set of
// regex patterns.
//
// It’s designed for preprocessing steps that need to rewrite specific constructs (like emoji
// shortcodes) while leaving everything else untouched. Each pattern is applied as a prefix match
// at the current cursor position, which keeps the tokenizer simple and predictable.
//
// This tokenizer is intentionally conservative: patterns are opt-in and processing is linear. If
// no patterns are provided, the input is returned as a single `.markup` token.

struct MarkupTokenizer {
  private let patterns: [Pattern]

  init(patterns: [Pattern]) {
    self.patterns = patterns
  }

  func tokenize(_ input: String) throws -> [Token] {
    guard !patterns.isEmpty else {
      return [.init(type: .markup, content: input)]
    }

    var tokens: [Token] = []
    var currentIndex = input.startIndex

    while currentIndex < input.endIndex {
      var matchFound = false

      // Try each pattern at the current position
      for pattern in patterns {
        guard let match = try pattern.regex.prefixMatch(in: input[currentIndex...]) else {
          continue
        }

        // Add any markup before the match
        if currentIndex < match.range.lowerBound {
          let markup = String(input[currentIndex..<match.range.lowerBound])
          tokens.append(.init(type: .markup, content: markup))
        }

        tokens.append(
          .init(
            type: pattern.tokenType,
            content: String(match.0),
            capturedContent: String(match.1)
          )
        )

        currentIndex = match.range.upperBound
        matchFound = true
        break
      }

      if !matchFound {
        // Append or create markup
        let nextIndex = input.index(after: currentIndex)
        let content = String(input[currentIndex])

        if let last = tokens.indices.last, tokens[last].type == .markup {
          tokens[last].content += content
        } else {
          tokens.append(.init(type: .markup, content: content))
        }
        currentIndex = nextIndex
      }
    }

    return tokens
  }
}

extension MarkupTokenizer {
  struct Pattern {
    let regex: Regex<(Substring, Substring)>
    let tokenType: TokenType
  }
}

extension MarkupTokenizer.Pattern {
  static var emoji: Self {
    .init(regex: /:([a-zA-Z0-9_+-]+):/, tokenType: .emoji)
  }
}

extension MarkupTokenizer {
  struct Token: Hashable, Sendable {
    let type: TokenType
    var content: String
    var capturedContent: String?
  }
}

extension MarkupTokenizer {
  struct TokenType: Hashable, RawRepresentable, Sendable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
      self.rawValue = value
    }
  }
}

extension MarkupTokenizer.TokenType {
  static let markup: Self = "markup"
  static let emoji: Self = "emoji"
}
