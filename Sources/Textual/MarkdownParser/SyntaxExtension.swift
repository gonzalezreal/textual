import Foundation

extension AttributedStringMarkdownParser {
  /// A syntax extension that replaces matched tokens after Markdown parsing.
  public struct SyntaxExtension {
    let patterns: [PatternTokenizer.Pattern]
    let replace:
      (
        _ token: PatternTokenizer.Token,
        _ attributes: AttributeContainer
      ) -> AttributedString?
  }
}

extension AttributedStringMarkdownParser.SyntaxExtension {
  /// Replaces `:shortcode:` sequences using the provided custom emoji definitions.
  public static func emoji(_ emoji: Set<Emoji>) -> Self {
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

  #if Math
    /// Replaces inline and block math expressions with attachments.
    public static var math: Self {
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
  #endif
}
