import SwiftUI

extension AttributeScopes {
  /// Attributes used by Textual when parsing and rendering markup.
  public struct TextualAttributes: AttributeScope {
    /// Stores an attachment value in attributed content.
    public enum AttachmentAttribute: AttributedStringKey {
      public typealias Value = AnyAttachment
      public static let name = "Textual.Attachment"
    }

    /// Stores a URL for a custom emoji placeholder.
    ///
    /// Textual uses this attribute as an intermediate representation before resolving emoji into
    /// an attachment.
    public enum EmojiURLAttribute: AttributedStringKey {
      public typealias Value = URL
      public static let name = "Textual.EmojiURL"
    }

    /// A property for accessing an attachment attribute.
    public let attachment: AttachmentAttribute

    /// A property for accessing an emoji URL attribute.
    public let emojiURL: EmojiURLAttribute

    public let foundation: AttributeScopes.FoundationAttributes
  }

  /// The Textual attribute scope.
  public var textual: TextualAttributes.Type {
    TextualAttributes.self
  }
}

extension AttributeDynamicLookup {
  /// Provides dynamic member lookup for Textual attributes.
  public subscript<T: AttributedStringKey>(
    dynamicMember keyPath: KeyPath<AttributeScopes.TextualAttributes, T>
  ) -> T {
    return self[T.self]
  }
}
