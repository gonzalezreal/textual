import SwiftUI

/// Loads attachments referenced by markup.
///
/// Textual uses attachment loaders to turn URLs (for example image links or custom emoji URLs)
/// into concrete ``Attachment`` values.
///
/// The default loaders fetch and decode images using Textual's built-in image loader. You can
/// supply custom loaders using ``TextualNamespace/imageAttachmentLoader(_:)`` and
/// ``TextualNamespace/emojiAttachmentLoader(_:)``.
///
/// Here’s a common pattern when your markup uses relative image URLs:
///
/// ```swift
/// StructuredText(
///   markdown: """
///     These images are using an `URLAttachmentLoader` instance
///     relative to `https://picsum.photos/seed/textual`:
///
///     ![](400/250)
///     ![](300/125)
///     """
/// )
/// .textual.imageAttachmentLoader(
///   .image(relativeTo: URL(string: "https://picsum.photos/seed/textual")!)
/// )
/// ```
///
/// If your markup uses asset names, map the URL to an asset catalog entry:
///
/// ```swift
/// let emoji: Set<Emoji> = [
///   Emoji(shortcode: "sad_dog", url: URL(string: "sad_dog")!)
/// ]
///
/// StructuredText(
///   markdown: "![Alt text](sad_dog) :sad_dog:",
///   patternOptions: .init(emoji: emoji)
/// )
/// .textual.imageAttachmentLoader(.image(named: \.lastPathComponent))
/// .textual.emojiAttachmentLoader(.emoji(named: \.lastPathComponent))
/// ```
public protocol AttachmentLoader: Sendable {
  associatedtype Attachment: Textual.Attachment

  /// Loads an attachment for the given URL.
  ///
  /// - Parameters:
  ///   - url: The URL found in the markup.
  ///   - text: The original text associated with the URL (for example, image alt text).
  ///   - environment: The current color environment, useful for appearance-aware attachments.
  func attachment(
    for url: URL,
    text: String,
    environment: ColorEnvironmentValues
  ) async throws -> Attachment
}

extension EnvironmentValues {
  @Entry var imageAttachmentLoader: any AttachmentLoader = .image()
  @Entry var emojiAttachmentLoader: any AttachmentLoader = .emoji()
}
