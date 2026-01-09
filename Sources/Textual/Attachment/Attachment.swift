import SwiftUI

/// Determines how text selection affects an attachment.
public enum AttachmentSelectionStyle: Sendable {
  /// Treats the attachment as inline text.
  ///
  /// Use this for glyph-like attachments (for example, custom emoji) that should not be dimmed
  /// when selected.
  case text

  /// Treats the attachment as an embedded object.
  ///
  /// Use this for object-like attachments (for example, images). On macOS, when the attachment is
  /// part of the selected range, Textual dims the rendered attachment view.
  case object
}

/// Provides a view that can be embedded inline in attributed text.
///
/// Attachments are resolved from markup and rendered inline by Textual. Use attachments to
/// display images, custom emoji, or other inline views that should participate in text layout.
public protocol Attachment: Sendable, Hashable, CustomStringConvertible {
  associatedtype Body: View

  /// Controls how text selection affects the attachment.
  ///
  /// The default implementation returns `.object`.
  var selectionStyle: AttachmentSelectionStyle { get }

  /// The view to render for this attachment.
  @ViewBuilder @MainActor var body: Body { get }

  /// Returns a baseline offset for the attachment.
  ///
  /// The default implementation returns `0`.
  func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat

  /// Returns the attachment size for the given proposal.
  func sizeThatFits(_ proposal: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize

  /// Returns a PNG representation of the attachment, if available.
  ///
  /// Implement this to provide PNG-encoded data for serialization, copy/paste,
  /// or export workflows. The default implementation returns `nil`.
  func pngData() -> Data?
}

extension Attachment {
  public var selectionStyle: AttachmentSelectionStyle {
    .object
  }

  public func baselineOffset(in _: TextEnvironmentValues) -> CGFloat {
    0
  }

  public func pngData() -> Data? {
    nil
  }
}

/// A type-erased ``Attachment``.
///
/// Textual uses `AnyAttachment` to store heterogeneous attachments in attributed content.
public struct AnyAttachment: Attachment {
  private let base: any Attachment

  /// Creates a type-erased attachment from a concrete attachment.
  public init(_ base: some Attachment) {
    if let base = base as? AnyAttachment {
      self = base
    } else {
      self.base = base
    }
  }

  /// Creates a type-erased attachment from an existential value.
  public init(_ base: any Attachment) {
    self.base = base
  }

  public var description: String {
    base.description
  }

  public var selectionStyle: AttachmentSelectionStyle {
    base.selectionStyle
  }

  public var body: AnyView {
    AnyView(base.body)
  }

  public func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat {
    base.baselineOffset(in: environment)
  }

  public func sizeThatFits(
    _ proposal: ProposedViewSize,
    in environment: TextEnvironmentValues
  ) -> CGSize {
    base.sizeThatFits(proposal, in: environment)
  }

  public func pngData() -> Data? {
    base.pngData()
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    AnyHashable(lhs.base) == AnyHashable(rhs.base)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}
