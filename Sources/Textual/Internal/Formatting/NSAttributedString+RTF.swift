#if canImport(AppKit)
  import AppKit
#elseif canImport(UIKit)
  import UIKit
#endif
import Foundation

extension Formatter {
  /// Encode the formatted content as RTF data for the system pasteboard.
  ///
  /// We round-trip through HTML rather than serializing the source
  /// `NSAttributedString` directly: Textual's runtime attributes use SwiftUI
  /// `Font` values that the RTF encoder ignores, so a direct serialization
  /// loses bold and heading styles. Parsing our well-formed HTML through
  /// `NSAttributedString(data:options:)` produces a native attributed string
  /// with proper `NSFont` weights and paragraph styles for headings, which
  /// then exports to RTF cleanly.
  ///
  /// RTF is the most reliable rich-text format for cross-application paste on
  /// macOS — Word, Pages, Apple Notes, and LibreOffice all prefer it over a
  /// bare HTML fragment.
  func rtfData() -> Data? {
    guard let htmlData = htmlDocument().data(using: .utf8) else {
      return nil
    }

    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
      .documentType: NSAttributedString.DocumentType.html,
      .characterEncoding: String.Encoding.utf8.rawValue,
    ]

    guard
      let attributed = try? NSAttributedString(
        data: htmlData,
        options: options,
        documentAttributes: nil
      )
    else {
      return nil
    }

    return try? attributed.data(
      from: NSRange(location: 0, length: attributed.length),
      documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )
  }
}
