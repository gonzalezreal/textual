import SwiftUI

/// Transforms an attributed string after parsing and before rendering.
///
/// `InlineText` and `StructuredText` parse markup into an `AttributedString` using a
/// ``MarkupParser``, resolve attachments, and then apply a postprocessor, giving you
/// a chance to add or modify attributes that are independent of the markup
/// itself — for example, highlighting search matches or annotating ranges.
///
/// This stage is separate from the ``MarkupParser`` because the data added by a postprocessor may
/// change independently of the markup content. A parser only runs when the input string changes,
/// so attributes whose source is external (a search query, a live filter) belong in a
/// postprocessor rather than in the parser. The postprocessor is re-invoked whenever either the
/// parsed attributed string or the postprocessor itself changes.
///
/// Apply a postprocessor using the ``TextualNamespace/attributedStringPostprocessor(_:)`` modifier:
///
/// ```swift
/// InlineText(markdown: "Hello, world")
///   .textual.attributedStringPostprocessor(SearchHighlighter(query: "world"))
/// ```
///
/// The postprocessor receives the full attributed string, including resolved attachments.
/// Ranges are valid against that complete string. Avoid dropping runs that carry
/// attachment attributes, as this desyncs the rendered attachments from the attributed content.
///
/// ### When the Postprocessor Runs
///
/// The postprocessor is invoked whenever the parsed attributed string or the postprocessor itself
/// changes. Equality is used to detect changes in the postprocessor, so the
/// conforming type must reflect any state that affects output in its `==` implementation.

public protocol AttributedStringPostprocessor: Hashable {
  /// Returns a transformed attributed string for rendering.
  ///
  /// - Parameter input: The parsed, attachment-resolved attributed string.
  /// - Returns: The attributed string to render.
  func postprocess(input: AttributedString) -> AttributedString
}
