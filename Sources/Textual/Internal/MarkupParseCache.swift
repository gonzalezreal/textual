import Foundation

/// Memoizes the parse of a markup string so a view can derive its content directly in `body`,
/// instead of seeding `@State` from appear events that a lazily materialized view may never receive.
@MainActor
final class MarkupParseCache {
  private var markup: String?
  private var parserKey: AnyHashable?
  private var attributedString = AttributedString()

  func attributedString(for markup: String, parser: any MarkupParser) -> AttributedString {
    if markup != self.markup || parser.cacheKey != parserKey {
      self.markup = markup
      self.parserKey = parser.cacheKey
      self.attributedString = (try? parser.attributedString(for: markup)) ?? .init()
    }
    return attributedString
  }
}
