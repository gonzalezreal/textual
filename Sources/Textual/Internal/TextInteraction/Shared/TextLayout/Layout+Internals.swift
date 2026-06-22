#if TEXTUAL_ENABLE_TEXT_SELECTION
  import CoreText
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension Text.Layout {
    struct Contents {
      let lineFragments: [NSTextLineFragment]
      let layoutAttributedStrings: [NSAttributedString]
      let attributedStrings: [NSAttributedString]
    }

    func materializeContents() -> Contents {
      let lineFragments = self.compactMap(\.lineFragment)
      let layoutAttributedStrings =
        lineFragments
        .map(\.attributedString)
        .removingIdenticalDuplicates()

      // Attachment attributes are replaced by placeholders in the rendering pipeline (see TextFragment)
      // We need to re-apply them to make them part of the contents during copy operations
      let attributedStrings = layoutAttributedStrings.map { input in
        // Get all the lines in the layout that reference the input
        let lines = zip(self, lineFragments)
          .filter { $1.attributedString === input }
          .map(\.0)

        return input.applyingAttachments(in: lines)
      }

      return .init(
        lineFragments: lineFragments,
        layoutAttributedStrings: layoutAttributedStrings,
        attributedStrings: attributedStrings
      )
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension Text.Layout.Line {
    var lineFragment: NSTextLineFragment? {
      let mirror = Mirror(reflecting: self)

      if #available(macOS 26.0, iOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        return mirror.descendant("_line", "nsLine", 0) as? NSTextLineFragment
      } else {
        return mirror.descendant("_line", "nsLine") as? NSTextLineFragment
      }
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension Text.Layout.Run {
    var characterRanges: [Range<Int>] {
      guard let ctRun else { return [] }
      assert(CTRunGetGlyphCount(ctRun) == self.count)

      let runRange = CTRunGetStringRange(ctRun)
      let start = runRange.location
      let end = start + runRange.length

      var characterIndices: [CFIndex]
      if let pointer = CTRunGetStringIndicesPtr(ctRun) {
        characterIndices = Array(UnsafeBufferPointer(start: pointer, count: count))
      } else {
        characterIndices = Array(repeating: 0, count: self.count)
        CTRunGetStringIndices(ctRun, .init(), &characterIndices)
      }

      var characterRanges: [Range<Int>] = []
      characterRanges.reserveCapacity(self.count)

      for i in 0..<self.count {
        let characterIndex = characterIndices[i]
        let boundary: CFIndex

        if case .leftToRight = self.layoutDirection {
          // Look forward to the next different character index
          var j = i + 1
          while j < self.count, characterIndices[j] == characterIndex { j += 1 }
          boundary = (j < self.count) ? characterIndices[j] : end
        } else {
          // Look backward to the previous different character index
          var j = i - 1
          while j >= 0, characterIndices[j] == characterIndex { j -= 1 }
          boundary = (j >= 0) ? characterIndices[j] : end
        }

        let lowerBound = Swift.max(Swift.min(characterIndex, boundary), start)
        let upperBound = Swift.min(Swift.max(characterIndex, boundary), end)

        characterRanges.append(lowerBound..<upperBound)
      }

      return characterRanges
    }

    var ctRun: CTRun? {
      let mirror = Mirror(reflecting: self)
      guard
        let index = mirror.descendant("index") as? Int,
        let lineRef = mirror.descendant("line") as? CFTypeRef,
        CFGetTypeID(lineRef) == CTLineGetTypeID()
      else {
        return nil
      }

      let ctLine = unsafeDowncast(lineRef, to: CTLine.self)
      guard let ctRuns = CTLineGetGlyphRuns(ctLine) as? [CTRun] else {
        return nil
      }
      return ctRuns[index]
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension NSAttributedString {
    fileprivate func applyingAttachments(in lines: [Text.Layout.Line]) -> NSAttributedString {
      guard lines.containsAttachments else {
        return self
      }

      let result = NSMutableAttributedString(attributedString: self)

      for line in lines {
        for run in line {
          guard
            let attachment = run.attachment,
            let range = run.characterRanges.first
          else { continue }

          result.addAttribute(.textual.attachment, value: attachment, range: NSRange(range))

          if let presentationIntent = run.attachmentPresentationIntent {
            result.addAttribute(
              .textual.presentationIntent, value: presentationIntent, range: NSRange(range))
          }
        }
      }

      return result
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension Array where Element == Text.Layout.Line {
    fileprivate var containsAttachments: Bool {
      self.contains { line in
        line.contains { run in
          run.attachment != nil
        }
      }
    }
  }
#endif
