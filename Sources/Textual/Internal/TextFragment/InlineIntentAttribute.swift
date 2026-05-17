import SwiftUI

// MARK: - Overview
//
// `InlineIntentAttribute` carries a run's `InlinePresentationIntent` (strong, emphasized,
// strikethrough, code) through SwiftUI's `Text` rendering pipeline.
//
// The Foundation built-in `NSInlinePresentationIntent` attribute is consumed by SwiftUI during
// rendering and does not appear on the resulting `NSTextLineFragment.attributedString`. Without it,
// the export `Formatter` cannot tell bold from regular text. We mirror the pattern used by
// `AttachmentAttribute` and `LinkAttribute`: attach a private `TextAttribute` per run in the
// `TextBuilder`, expose it from `Text.Layout.Run`, and re-apply it onto the `NSAttributedString`
// during materialization so downstream consumers see the standard Foundation attribute again.

struct InlineIntentAttribute: TextAttribute {
  var rawValue: UInt

  init(_ intent: InlinePresentationIntent) {
    self.rawValue = intent.rawValue
  }

  var intent: InlinePresentationIntent {
    InlinePresentationIntent(rawValue: rawValue)
  }
}

extension Text.Layout.Run {
  var inlineIntent: InlinePresentationIntent? {
    self[InlineIntentAttribute.self]?.intent
  }
}
