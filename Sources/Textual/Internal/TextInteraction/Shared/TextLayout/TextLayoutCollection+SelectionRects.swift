#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  // MARK: - Overview
  //
  // Selection rectangles are derived from run-slice geometry, then merged into spans that feel
  // continuous when drawn.
  //
  // The algorithm walks the run slices in a range, merges adjacent slices that share a layout
  // direction (to avoid breaking RTL selection into multiple rectangles), then trims the leading
  // and trailing spans to caret positions. Finally, it “inflates” per-line rectangles to fill any
  // vertical gaps between lines so selection highlights appear as a single block.

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayoutCollection {
    func selectionRects(for range: TextRange, layout: Text.Layout) -> [TextSelectionRect] {
      guard
        let layoutIndex = self.index(of: layout),
        let clampedRange = self.clampRange(range, layoutIndex: layoutIndex)
      else {
        return []
      }

      let origin = layouts[layoutIndex].origin

      return self.selectionRects(for: clampedRange).map { rect in
        rect.offsetBy(dx: -origin.x, dy: -origin.y)
      }
    }

    func selectionRects(for range: TextRange) -> [TextSelectionRect] {
      guard !range.isCollapsed else { return [] }

      let startX = self.caretRect(for: range.start).minX
      let endX = self.caretRect(for: range.end).minX

      let start = range.start.indexPath
      let end = range.end.indexPath

      var selectionRects: [TextSelectionRect] = []
      var currentLayout: Int? = nil
      var builder: TextSelectionRect.Builder? = nil

      func flushRects() {
        selectionRects += builder?.rects() ?? []
        builder = nil
      }

      for indexPath in self.indexPathsForRunSlices(in: range) {
        if currentLayout != indexPath.layout {
          flushRects()
          currentLayout = indexPath.layout
          builder = .init(
            start: indexPath.layout == start.layout ? start : nil,
            end: indexPath.layout == end.layout ? end : nil,
            startX: startX,
            endX: endX
          )
        }

        let rect = runSliceSelectionRect(at: indexPath)
        let layoutDirection = self.layoutDirection(at: indexPath)

        builder?.appendRect(rect, layoutDirection: layoutDirection, line: indexPath.line)
      }

      flushRects()

      guard !selectionRects.isEmpty else {
        return []
      }

      selectionRects[0].containsStart = true
      selectionRects[selectionRects.count - 1].containsEnd = true

      return selectionRects
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextSelectionRect {
    fileprivate struct Builder {
      let start: IndexPath?
      let end: IndexPath?
      let startX: CGFloat
      let endX: CGFloat

      private var lines: [[TextSelectionRect]] = []
      private var currentLine: Int?
      private var currentLineRects: [TextSelectionRect] = []

      init(
        start: IndexPath?,
        end: IndexPath?,
        startX: CGFloat,
        endX: CGFloat
      ) {
        self.start = start
        self.end = end
        self.startX = startX
        self.endX = endX
      }

      mutating func appendRect(_ rect: CGRect, layoutDirection: LayoutDirection, line: Int) {
        if currentLine != line {
          appendCurrentLine()
          currentLine = line
        }

        if let last = currentLineRects.indices.last,
          currentLineRects[last].layoutDirection == layoutDirection
        {
          currentLineRects[last].rect = currentLineRects[last].rect.union(rect)
        } else {
          currentLineRects.append(.init(rect: rect, layoutDirection: layoutDirection))
        }
      }

      mutating func rects() -> [TextSelectionRect] {
        appendCurrentLine()
        guard !lines.isEmpty else {
          return []
        }
        lines.inflate()
        return lines.flatMap(\.self)
      }

      private mutating func appendCurrentLine() {
        guard let currentLine, !currentLineRects.isEmpty else {
          currentLineRects.removeAll(keepingCapacity: true)
          self.currentLine = nil
          return
        }

        if let start, start.line == currentLine {
          let span = currentLineRects.index(containing: startX) ?? currentLineRects.startIndex
          currentLineRects[span].trimLeading(to: startX)
        }

        if let end, end.line == currentLine {
          let span =
            currentLineRects.index(containing: endX)
            ?? currentLineRects.index(before: currentLineRects.endIndex)
          currentLineRects[span].trimTrailing(to: endX)
        }

        lines.append(currentLineRects)
        currentLineRects.removeAll(keepingCapacity: true)
        self.currentLine = nil
      }
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension Array where Element == [TextSelectionRect] {
    fileprivate mutating func inflate() {
      var previousMaxY: CGFloat? = nil

      for line in self.indices {
        guard !self[line].isEmpty else {
          continue
        }

        if let previousMaxY {
          let lineMinY = self[line].first!.rect.minY
          if lineMinY > previousMaxY {
            let gap = lineMinY - previousMaxY
            for span in self[line].indices {
              self[line][span].rect.origin.y -= gap
              self[line][span].rect.size.height += gap
            }
          }
        }

        previousMaxY = self[line].first?.rect.maxY
      }
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension Array where Element == TextSelectionRect {
    fileprivate func index(containing caretX: CGFloat) -> Int? {
      firstIndex {
        $0.rect.minX...$0.rect.maxX ~= caretX
      }
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextSelectionRect {
    fileprivate mutating func trimLeading(to caretX: CGFloat) {
      if layoutDirection == .leftToRight {
        let minX = max(rect.minX, caretX)
        rect.size.width = max(0, rect.maxX - minX)
        rect.origin.x = minX
      } else {
        let maxX = max(rect.minX, caretX)
        rect.size.width = Swift.max(0, maxX - rect.minX)
      }
    }

    fileprivate mutating func trimTrailing(to caretX: CGFloat) {
      if layoutDirection == .leftToRight {
        let maxX = max(rect.minX, caretX)
        rect.size.width = Swift.max(0, maxX - rect.minX)
      } else {
        let minX = Swift.min(rect.maxX, caretX)
        rect.size.width = Swift.max(0, rect.maxX - minX)
        rect.origin.x = minX
      }
    }
  }
#endif
