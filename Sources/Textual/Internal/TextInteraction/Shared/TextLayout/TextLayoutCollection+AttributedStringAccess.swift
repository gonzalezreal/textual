#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayoutCollection {
    var stringLength: Int {
      layouts.map(\.attributedString.length).reduce(0, +)
    }

    func attributedText(in range: TextRange) -> NSAttributedString {
      guard !range.isCollapsed else { return NSAttributedString() }

      let attributedText = NSMutableAttributedString()
      let start = range.start.indexPath.layout
      let end = range.end.indexPath.layout

      for layout in start...end {
        let attributedString = layouts[layout].attributedString

        let lowerBound =
          (layout == start)
          ? localCharacterIndex(at: range.start)
          : 0
        let upperBound =
          (layout == end)
          ? localCharacterIndex(at: range.end)
          : attributedString.length

        if lowerBound < upperBound {
          attributedText.append(
            attributedString.attributedSubstring(
              from: NSRange(lowerBound..<upperBound)
            )
          )
        }
      }

      return attributedText
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayout {
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func wordRange(containing characterIndex: Int) -> NSRange? {
      #if os(macOS)
        guard
          NSRange(location: 0, length: attributedString.length)
            .contains(characterIndex)
        else {
          return nil
        }
        return attributedString.doubleClick(at: characterIndex)
      #else
        nil
      #endif
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension NSAttributedString {
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func nextWord(from characterIndex: Int) -> Int {
      #if os(macOS)
        nextWord(from: characterIndex, forward: true)
      #else
        0
      #endif
    }

    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func previousWord(from characterIndex: Int) -> Int {
      #if os(macOS)
        nextWord(from: characterIndex, forward: false)
      #else
        0
      #endif
    }
  }
#endif
