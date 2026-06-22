#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI

  // MARK: - Overview
  //
  // We implement `UITextInputTokenizer` so word and sentence selection respects block boundaries.
  //
  // UIKit’s `UITextInputStringTokenizer` doesn’t understand that runs in different presentation
  // intents (paragraphs, list items, code blocks, and so on) are semantically separate. Without a
  // custom tokenizer, gestures like double-tap can select across blocks—for example, selecting a
  // word at the start of a paragraph and accidentally including text from the previous block.
  //
  // By clamping word and sentence operations to the current block range reported by the model, the
  // selection behavior matches the document’s structure.

  @available(iOS 18, *)
  extension UITextInteractionView: UITextInputTokenizer {
    func rangeEnclosingPosition(
      _ position: UITextPosition,
      with granularity: UITextGranularity,
      inDirection direction: UITextDirection
    ) -> UITextRange? {
      guard granularity == .word || granularity == .sentence else {
        return _tokenizer.rangeEnclosingPosition(
          position,
          with: granularity,
          inDirection: direction
        )
      }

      guard
        let range = _tokenizer.rangeEnclosingPosition(
          position,
          with: granularity,
          inDirection: direction
        ),
        let rangeBox = range as? TextRangeBox
      else {
        return nil
      }

      guard let positionBox = position as? TextPositionBox else {
        return range
      }

      let rawStart = rangeBox.wrappedStart
      let rawEnd = rangeBox.wrappedEnd
      let rawPosition = positionBox.wrappedValue

      guard let blockRange = model.blockRange(for: rawPosition) else {
        return range
      }

      // Clamp the range to stay within the layout boundaries
      let clampedRange = TextRange(
        start: max(rawStart, blockRange.start),
        end: min(rawEnd, blockRange.end)
      )

      return TextRangeBox(clampedRange)
    }

    func isPosition(
      _ position: UITextPosition,
      atBoundary granularity: UITextGranularity,
      inDirection direction: UITextDirection
    ) -> Bool {
      guard
        granularity == .word || granularity == .sentence,
        let positionBox = position as? TextPositionBox
      else {
        return _tokenizer.isPosition(position, atBoundary: granularity, inDirection: direction)
      }

      let rawPosition = positionBox.wrappedValue

      if model.isPositionAtBlockBoundary(rawPosition) {
        return true
      }

      return _tokenizer.isPosition(position, atBoundary: granularity, inDirection: direction)
    }

    func position(
      from position: UITextPosition,
      toBoundary granularity: UITextGranularity,
      inDirection direction: UITextDirection
    ) -> UITextPosition? {
      guard granularity == .word || granularity == .sentence else {
        return _tokenizer.position(from: position, toBoundary: granularity, inDirection: direction)
      }

      // Get the boundary position from the system tokenizer
      guard
        let boundaryPosition = _tokenizer.position(
          from: position,
          toBoundary: granularity,
          inDirection: direction
        ),
        let boundaryPositionBox = boundaryPosition as? TextPositionBox
      else {
        return nil
      }

      guard let positionBox = position as? TextPositionBox else {
        return boundaryPosition
      }
      let rawStart = positionBox.wrappedValue
      let rawEnd = boundaryPositionBox.wrappedValue

      if rawStart.indexPath.layout != rawEnd.indexPath.layout {
        // If they're in different layouts, we need to clamp to the layout boundary
        switch direction {
        case .storage(.forward):
          // Stop at the end of the current layout
          if let layoutEnd = model.blockEnd(for: rawStart) {
            return TextPositionBox(layoutEnd)
          }
        case .storage(.backward):
          // Stop at the start of the current layout
          return TextPositionBox(
            .init(
              indexPath: .init(
                layout: rawStart.indexPath.layout
              ),
              affinity: .downstream
            )
          )
        default:
          break
        }
      }

      return boundaryPosition
    }

    func isPosition(
      _ position: UITextPosition,
      withinTextUnit granularity: UITextGranularity,
      inDirection direction: UITextDirection
    ) -> Bool {
      guard
        granularity == .word || granularity == .sentence,
        let positionBox = position as? TextPositionBox
      else {
        return _tokenizer.isPosition(position, withinTextUnit: granularity, inDirection: direction)
      }

      let rawPosition = positionBox.wrappedValue

      // If we're at a block boundary, extending in the direction
      // that crosses the boundary would leave the text unit
      if model.isPositionAtBlockBoundary(rawPosition) {
        // At start and moving backward, would cross boundary
        if case .storage(.backward) = direction,
          rawPosition
            == TextPosition(
              indexPath: .init(layout: rawPosition.indexPath.layout),
              affinity: .downstream
            )
        {
          return false
        }

        // At end and moving forward, would cross boundary
        if case .storage(.forward) = direction,
          rawPosition == model.blockEnd(for: rawPosition)
        {
          return false
        }
      }

      return _tokenizer.isPosition(position, withinTextUnit: granularity, inDirection: direction)
    }
  }
#endif
