import Foundation

// MARK: - Overview
//
// `PatternTokenizer` scans source text and splits it into tokens based on a small set of
// regex patterns.
//
// It’s designed for postprocessing steps that need to rewrite specific constructs (like emoji
// shortcodes) while leaving everything else untouched. Each pattern is applied as a prefix match
// at the current cursor position, which keeps the tokenizer simple and predictable.
//
// This tokenizer is intentionally conservative: patterns are opt-in and processing is linear. If
// no patterns are provided, the input is returned as a single `.text` token.

struct PatternTokenizer {
  private let patterns: [Pattern]

  init(patterns: [Pattern]) {
    self.patterns = patterns
  }

  func tokenize(_ input: String) throws -> [Token] {
    guard !patterns.isEmpty else {
      return [.init(type: .text, content: input)]
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

        // Add any text before the match
        if currentIndex < match.range.lowerBound {
          let markup = String(input[currentIndex..<match.range.lowerBound])
          tokens.append(.init(type: .text, content: markup))
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
        // Append or create text
        let nextIndex = input.index(after: currentIndex)
        let content = String(input[currentIndex])

        if let last = tokens.indices.last, tokens[last].type == .text {
          tokens[last].content += content
        } else {
          tokens.append(.init(type: .text, content: content))
        }
        currentIndex = nextIndex
      }
    }

    return tokens
  }
}

extension PatternTokenizer {
  struct Pattern {
    let regex: Regex<(Substring, Substring)>
    let tokenType: TokenType
  }
}

extension PatternTokenizer.Pattern {
  static var emoji: Self {
    .init(regex: /:([a-zA-Z0-9_+-]+):/, tokenType: .emoji)
  }

  static var mathBlock: Self {
    .init(regex: /(?s)\$\$(.+?)\$\$/, tokenType: .mathBlock)
  }

  static var mathInline: Self {
    .init(regex: /\$(?!\$)((?:\\\$|[^$\n])+)\$/, tokenType: .mathInline)
  }
}

extension PatternTokenizer {
  struct Token: Hashable, Sendable {
    let type: TokenType
    var content: String
    var capturedContent: String?
  }
}

extension PatternTokenizer {
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

extension PatternTokenizer.TokenType {
  static let text: Self = "text"
  static let emoji: Self = "emoji"
  static let mathBlock: Self = "mathBlock"
  static let mathInline: Self = "mathInline"
}
