#if TEXTUAL_ENABLE_TEXT_SELECTION
  import CoreText
  import SwiftUI

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

      // Attachment and inline-intent attributes are stripped or replaced in the rendering pipeline
      // (see TextFragment). Re-apply them so downstream consumers (export formatters, etc.) see
      // the same attributes that the source AttributedString carried.
      let attributedStrings = layoutAttributedStrings.map { input in
        // Get all the lines in the layout that reference the input
        let lines = zip(self, lineFragments)
          .filter { $1.attributedString === input }
          .map(\.0)

        return input.applyingPreservedAttributes(in: lines)
      }

      return .init(
        lineFragments: lineFragments,
        layoutAttributedStrings: layoutAttributedStrings,
        attributedStrings: attributedStrings
      )
    }
  }

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

  extension NSAttributedString {
    fileprivate func applyingPreservedAttributes(in lines: [Text.Layout.Line]) -> NSAttributedString {
      guard lines.hasPreservedAttributes else {
        return self
      }

      let result = NSMutableAttributedString(attributedString: self)

      for line in lines {
        for run in line {
          let characterRanges = run.characterRanges
          guard let firstRange = characterRanges.first else { continue }

          // Attachments are single glyphs, so the first range alone covers them.
          if let attachment = run.attachment {
            let nsRange = NSRange(firstRange)
            result.addAttribute(.textual.attachment, value: attachment, range: nsRange)
            if let presentationIntent = run.attachmentPresentationIntent {
              result.addAttribute(
                .textual.presentationIntent, value: presentationIntent, range: nsRange)
            }
          }

          // Inline intent spans the full run; cover every glyph's character range.
          if let inlineIntent = run.inlineIntent, !inlineIntent.isEmpty {
            for range in characterRanges {
              result.addAttribute(
                .textual.inlinePresentationIntent,
                value: inlineIntent.rawValue,
                range: NSRange(range))
            }
          }
        }
      }

      return result
    }
  }

  extension Array where Element == Text.Layout.Line {
    fileprivate var hasPreservedAttributes: Bool {
      self.contains { line in
        line.contains { run in
          run.attachment != nil || run.inlineIntent != nil
        }
      }
    }
  }
#endif
