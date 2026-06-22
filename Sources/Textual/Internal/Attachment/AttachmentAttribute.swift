import SwiftUI

// MARK: - Overview
//
// Attachments are stored in attributed content as a `Textual.Attachment` attribute, but SwiftUI
// `Text` can’t embed arbitrary views. The rendering pipeline converts these runs into placeholder
// `Text` segments and uses an overlay to draw the real views at the resolved layout positions.
//
// `AttachmentAttribute` is attached to the placeholder runs during `Text` construction. It carries:
// - the original attachment value (type-erased as `AnyAttachment`)
// - the run's `PresentationIntent` (used by formatters and higher-level rendering)
//
// `Text.Layout.Run` exposes lightweight accessors so overlay code can discover attachments without
// reaching back into the original attributed string.

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct AttachmentAttribute: TextAttribute {
  var attachment: AnyAttachment
  var presentationIntent: PresentationIntent?

  init(_ attachment: AnyAttachment, presentationIntent: PresentationIntent?) {
    self.attachment = attachment
    self.presentationIntent = presentationIntent
  }
}

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
extension Text.Layout.Run {
  var attachment: AnyAttachment? {
    self[AttachmentAttribute.self]?.attachment
  }

  var attachmentPresentationIntent: PresentationIntent? {
    self[AttachmentAttribute.self]?.presentationIntent
  }
}
