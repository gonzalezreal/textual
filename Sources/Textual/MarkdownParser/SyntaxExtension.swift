import Foundation

extension AttributedStringMarkdownParser {
  /// A syntax extension that replaces matched tokens after Markdown parsing.
  public struct SyntaxExtension {
    /// What the extension was made from; two extensions with the same key parse the same way.
    let cacheKey: AnyHashable
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
      return Self(cacheKey: "emoji", patterns: [], replace: { _, _ in nil })
    }

    let emojiMap = Dictionary(
      uniqueKeysWithValues: emoji.map { emoji in
        (emoji.shortcode, emoji)
      }
    )

    return Self(cacheKey: "emoji:" + emoji.map(\.shortcode).sorted().joined(separator: ","), patterns: [.emoji]) { token, attributes in
      guard let shortcode = token.capturedContent, let emoji = emojiMap[shortcode] else {
        return nil
      }

      return AttributedString(
        shortcode,
        attributes: attributes.emojiURL(emoji.url)
      )
    }
  }

  /// Replaces inline and block math expressions with attachments.
  public static var math: Self {
    .init(cacheKey: "math", patterns: [.mathBlock, .mathInline]) { token, attributes in
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
