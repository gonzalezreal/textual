#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  extension TextLayoutCollection {
    func url(for point: CGPoint) -> URL? {
      guard let layout = layouts.first(where: { $0.frame.contains(point) }) else {
        return nil
      }

      let localPoint = CGPoint(
        x: point.x - layout.origin.x,
        y: point.y - layout.origin.y
      )

      let url = layout.runs.first {
        $0.typographicBounds.contains(localPoint)
      }?.url

      return url
    }

    func firstRect(for range: TextRange) -> CGRect {
      guard !range.isCollapsed else {
        return caretRect(for: range.start)
      }

      var firstRect = CGRect.null
      let layout = range.start.indexPath.layout
      let line = range.start.indexPath.line

      for indexPath in indexPathsForRunSlices(in: range) {
        guard indexPath.layout == layout, indexPath.line == line else {
          break
        }
        firstRect = firstRect.union(runSliceSelectionRect(at: indexPath))
      }

      return firstRect
    }

    func caretRect(for position: TextPosition) -> CGRect {
      let runSliceRect = runSliceRect(at: position.indexPath)
      let lineRect = lineRect(at: position.indexPath)
      let layoutDirection = layoutDirection(at: position.indexPath)
      let x =
        (position.affinity == .downstream)
        ? runSliceRect.leadingEdgeX(for: layoutDirection)
        : runSliceRect.trailingEdgeX(for: layoutDirection)

      return CGRect(x: x, y: lineRect.minY, width: 1, height: lineRect.height)
    }

    func closestPosition(to point: CGPoint) -> TextPosition? {
      guard !layouts.isEmpty else { return nil }

      let layoutIndex = layoutIndex(closestTo: point)
      let layout = layouts[layoutIndex]

      guard !layout.lines.isEmpty else { return nil }

      let localPoint = CGPoint(
        x: point.x - layout.origin.x,
        y: point.y - layout.origin.y
      )

      let lineIndex = layout.lineIndex(closestToY: localPoint.y)
      let line = layout.lines[lineIndex]
      let runIndex = line.runIndex(closestToX: localPoint.x)
      let run = line.runs[runIndex]
      let direction = run.layoutDirection

      let runSliceIndex = run.sliceIndex(closestToX: localPoint.x)
      let runSlice = run.slices[runSliceIndex]

      let leadingDistance = abs(
        localPoint.x - runSlice.typographicBounds.leadingEdgeX(for: direction)
      )
      let trailingDistance = abs(
        localPoint.x - runSlice.typographicBounds.trailingEdgeX(for: direction)
      )

      return TextPosition(
        indexPath: .init(
          runSlice: runSliceIndex,
          run: runIndex,
          line: lineIndex,
          layout: layoutIndex
        ),
        affinity: (leadingDistance <= trailingDistance) ? .downstream : .upstream
      )
    }

    func characterRange(at point: CGPoint) -> TextRange? {
      guard !layouts.isEmpty else { return nil }

      let layoutIndex = layoutIndex(closestTo: point)
      let layout = layouts[layoutIndex]

      guard !layout.lines.isEmpty else { return nil }

      let localPoint = CGPoint(
        x: point.x - layout.origin.x,
        y: point.y - layout.origin.y
      )

      let lineIndex = layout.lineIndex(closestToY: localPoint.y)
      let line = layout.lines[lineIndex]
      let runIndex = line.runIndex(closestToX: localPoint.x)
      let run = line.runs[runIndex]
      let runSliceIndex = run.sliceIndex(closestToX: localPoint.x)

      let start = TextPosition(
        indexPath: .init(
          runSlice: runSliceIndex, run: runIndex, line: lineIndex, layout: layoutIndex),
        affinity: .downstream
      )
      let end = TextPosition(
        indexPath: .init(
          runSlice: runSliceIndex, run: runIndex, line: lineIndex, layout: layoutIndex),
        affinity: .upstream
      )

      return TextRange(start: start, end: end)
    }

    func isPositionAtBlockBoundary(_ position: TextPosition) -> Bool {
      if position
        == TextPosition(
          indexPath: .init(layout: position.indexPath.layout),
          affinity: .downstream
        )
      {
        return true
      }

      let layout = layouts[position.indexPath.layout]

      guard
        let line = layout.lines.last,
        let run = line.runs.last
      else {
        return false
      }

      if position
        == TextPosition(
          indexPath: .init(
            runSlice: run.slices.endIndex - 1,
            run: line.runs.endIndex - 1,
            line: layout.lines.endIndex - 1,
            layout: position.indexPath.layout
          ),
          affinity: .upstream
        )
      {
        return true
      }

      return false
    }

    func positionAbove(_ position: TextPosition, anchor: TextPosition) -> TextPosition? {
      let anchorX = runSliceRect(at: anchor.indexPath).midX

      if position.indexPath.line > 0 {
        return closestPosition(
          to: anchorX,
          layoutIndex: position.indexPath.layout,
          lineIndex: position.indexPath.line - 1
        )
      }

      if position.indexPath.layout > 0 {
        let previousLayout = layouts[position.indexPath.layout - 1]
        let lastLineIndex = previousLayout.lines.endIndex - 1
        return closestPosition(
          to: anchorX,
          layoutIndex: position.indexPath.layout - 1,
          lineIndex: lastLineIndex
        )
      }

      return startPosition
    }

    func positionBelow(_ position: TextPosition, anchor: TextPosition) -> TextPosition? {
      let anchorX = runSliceRect(at: anchor.indexPath).midX
      let layout = layouts[position.indexPath.layout]

      if position.indexPath.line + 1 < layout.lines.endIndex {
        return closestPosition(
          to: anchorX,
          layoutIndex: position.indexPath.layout,
          lineIndex: position.indexPath.line + 1
        )
      }

      if position.indexPath.layout + 1 < layouts.endIndex {
        return closestPosition(
          to: anchorX,
          layoutIndex: position.indexPath.layout + 1,
          lineIndex: 0
        )
      }

      return endPosition
    }

    func runSliceSelectionRect(at indexPath: IndexPath) -> CGRect {
      let layout = layouts[indexPath.layout]
      let line = layout.lines[indexPath.line]
      let runSlice = line.runs[indexPath.run].slices[indexPath.runSlice]

      var rect = runSlice.typographicBounds
      rect.origin.y = line.typographicBounds.minY
      rect.size.height = line.typographicBounds.height

      return rect.offsetBy(dx: layout.origin.x, dy: layout.origin.y)
    }
  }

  extension TextLayoutCollection {
    fileprivate func closestPosition(
      to x: CGFloat,
      layoutIndex: Int,
      lineIndex: Int
    ) -> TextPosition? {
      let layout = layouts[layoutIndex]
      let line = layout.lines[lineIndex]
      let runIndex = line.runIndex(closestToX: x)
      let run = line.runs[runIndex]
      let direction = run.layoutDirection

      let runSliceIndex = run.sliceIndex(closestToX: x)
      let runSlice = run.slices[runSliceIndex]

      let leadingDistance = abs(
        x - runSlice.typographicBounds.leadingEdgeX(for: direction)
      )
      let trailingDistance = abs(
        x - runSlice.typographicBounds.trailingEdgeX(for: direction)
      )

      return TextPosition(
        indexPath: .init(
          runSlice: runSliceIndex,
          run: runIndex,
          line: lineIndex,
          layout: layoutIndex
        ),
        affinity: (leadingDistance <= trailingDistance) ? .downstream : .upstream
      )
    }

    fileprivate func runSliceRect(at indexPath: IndexPath) -> CGRect {
      let layout = layouts[indexPath.layout]
      let runSlice = layout.lines[indexPath.line].runs[indexPath.run].slices[indexPath.runSlice]
      return runSlice.typographicBounds.offsetBy(dx: layout.origin.x, dy: layout.origin.y)
    }

    fileprivate func lineRect(at indexPath: IndexPath) -> CGRect {
      let layout = layouts[indexPath.layout]
      let line = layout.lines[indexPath.line]
      return line.typographicBounds.offsetBy(dx: layout.origin.x, dy: layout.origin.y)
    }

    fileprivate func layoutIndex(closestTo point: CGPoint) -> Int {
      var closestIndex = 0
      var closestDistance = CGFloat.greatestFiniteMagnitude
      for (index, layout) in zip(layouts.indices, layouts) {
        let distance = layout.frame.distanceSquared(to: point)
        if distance < closestDistance {
          closestDistance = distance
          closestIndex = index
        }
      }
      return closestIndex
    }
  }

  extension TextLayout {
    fileprivate func lineIndex(closestToY y: CGFloat) -> Int {
      var closestIndex = 0
      var closestDistance = CGFloat.greatestFiniteMagnitude
      for (index, line) in lines.enumerated() {
        let distance = line.typographicBounds.verticalDistance(to: y)
        if distance < closestDistance {
          closestDistance = distance
          closestIndex = index
        }
      }
      return closestIndex
    }
  }

  extension TextLine {
    fileprivate func runIndex(closestToX x: CGFloat) -> Int {
      var closestIndex = 0
      var closestDistance = CGFloat.greatestFiniteMagnitude
      for (index, run) in runs.enumerated() {
        let distance = run.typographicBounds.horizontalDistance(to: x)
        if distance < closestDistance {
          closestDistance = distance
          closestIndex = index
        }
      }
      return closestIndex
    }
  }

  extension TextRun {
    fileprivate func sliceIndex(closestToX x: CGFloat) -> Int {
      var closestIndex = 0
      var closestDistance = CGFloat.greatestFiniteMagnitude
      for (index, slice) in slices.enumerated() {
        let distance = slice.typographicBounds.horizontalDistance(to: x)
        if distance < closestDistance {
          closestDistance = distance
          closestIndex = index
        }
      }
      return closestIndex
    }
  }

  extension CGRect {
    fileprivate func leadingEdgeX(for layoutDirection: LayoutDirection) -> CGFloat {
      layoutDirection == .leftToRight ? minX : maxX
    }

    fileprivate func trailingEdgeX(for layoutDirection: LayoutDirection) -> CGFloat {
      layoutDirection == .leftToRight ? maxX : minX
    }

    // Vertical distance from this rect to a Y coordinate in the same space.
    // Returns 0 when `y` is inside the rect’s vertical span.
    fileprivate func verticalDistance(to y: CGFloat) -> CGFloat {
      if y < minY { return minY - y }
      if y > maxY { return y - maxY }
      return 0
    }

    // Horizontal distance from this rect to an X coordinate in the same space.
    // Returns 0 when `x` is inside the rect’s horizontal span.
    fileprivate func horizontalDistance(to x: CGFloat) -> CGFloat {
      if x < minX { return minX - x }
      if x > maxX { return x - maxX }
      return 0
    }

    fileprivate func distanceSquared(to point: CGPoint) -> CGFloat {
      let dx = horizontalDistance(to: point.x)
      let dy = verticalDistance(to: point.y)
      return dx * dx + dy * dy
    }
  }
#endif
