#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  extension TextLayoutCollection {
    var startPosition: TextPosition {
      // The first layout can be empty (a blank paragraph, say); the document starts at the first slice there is.
      for (layoutIndex, layout) in layouts.enumerated() {
        for (lineIndex, line) in layout.lines.enumerated() {
          for (runIndex, run) in line.runs.enumerated() where !run.slices.isEmpty {
            return TextPosition(
              indexPath: .init(runSlice: 0, run: runIndex, line: lineIndex, layout: layoutIndex),
              affinity: .downstream
            )
          }
        }
      }
      return TextPosition(indexPath: .init(runSlice: 0, run: 0, line: 0, layout: 0), affinity: .upstream)
    }

    var endPosition: TextPosition {
      for (layoutIndex, layout) in layouts.enumerated().reversed() {
        for (lineIndex, line) in layout.lines.enumerated().reversed() {
          for (runIndex, run) in line.runs.enumerated().reversed() where !run.slices.isEmpty {
            return TextPosition(
              indexPath: .init(runSlice: run.slices.endIndex - 1, run: runIndex, line: lineIndex, layout: layoutIndex),
              affinity: .upstream
            )
          }
        }
      }
      return startPosition
    }

    func position(from position: TextPosition, offset: Int) -> TextPosition? {
      let from = characterIndex(at: position)
      let target = from + offset

      guard (0...stringLength).contains(target) else {
        return nil
      }

      // Map target to layout and local character index

      var localTarget = target
      var layout = 0

      while layout < layouts.count {
        let length = layouts[layout].attributedString.length

        guard localTarget > length else {
          break
        }

        localTarget -= length
        layout += 1
      }

      guard layout < layouts.count else {
        return endPosition
      }

      return self.position(at: layout, localCharacterIndex: localTarget)
    }

    func characterIndex(at position: TextPosition) -> Int {
      let base = layouts.prefix(position.indexPath.layout)
        .map(\.attributedString.length)
        .reduce(0, +)
      return base + localCharacterIndex(at: position)
    }

    func localCharacterIndex(at position: TextPosition) -> Int {
      let range = localCharacterRange(at: position.indexPath)
      switch position.affinity {
      case .downstream: return range.lowerBound
      case .upstream: return range.upperBound
      }
    }

    func localCharacterRange(at indexPath: IndexPath) -> Range<Int> {
      // A layout without lines (an empty paragraph) has no slice to name; the position is its start.
      guard let slice = runSlice(at: indexPath) else {
        return 0..<0
      }
      return slice.characterRange
    }

    func layoutDirection(at indexPath: IndexPath) -> LayoutDirection {
      guard let line = layouts[safe: indexPath.layout]?.lines[safe: indexPath.line],
        let run = line.runs[safe: indexPath.run]
      else {
        return .leftToRight
      }
      return run.layoutDirection
    }

    private func runSlice(at indexPath: IndexPath) -> (any TextRunSlice)? {
      layouts[safe: indexPath.layout]?.lines[safe: indexPath.line]?.runs[safe: indexPath.run]?
        .slices[safe: indexPath.runSlice]
    }

    func position(at layoutIndex: Int, localCharacterIndex: Int) -> TextPosition? {
      guard localCharacterIndex > 0 else {
        return TextPosition(
          indexPath: .init(layout: layoutIndex),
          affinity: .downstream
        )
      }

      let layout = layouts[layoutIndex]
      let stringLength = layout.attributedString.length

      guard localCharacterIndex <= stringLength else {
        if let line = layout.lines.last, let run = line.runs.last {
          return TextPosition(
            indexPath: .init(
              runSlice: run.slices.endIndex - 1,
              run: line.runs.endIndex - 1,
              line: layout.lines.endIndex - 1,
              layout: layoutIndex
            ),
            affinity: .upstream
          )
        } else {
          return TextPosition(
            indexPath: .init(runSlice: 0, run: 0, line: 0, layout: layoutIndex),
            affinity: .upstream
          )
        }
      }

      for (i, line) in zip(layout.lines.indices, layout.lines) {
        for (j, run) in zip(line.runs.indices, line.runs) {
          for (k, slice) in zip(run.slices.indices, run.slices) {
            if slice.characterRange.contains(localCharacterIndex) {
              return TextPosition(
                indexPath: .init(
                  runSlice: k,
                  run: j,
                  line: i,
                  layout: layoutIndex
                ),
                affinity: .downstream
              )
            } else if slice.characterRange.upperBound == localCharacterIndex {
              return TextPosition(
                indexPath: .init(
                  runSlice: k,
                  run: j,
                  line: i,
                  layout: layoutIndex
                ),
                affinity: .upstream
              )
            }
          }
        }
      }

      return nil
    }

    func reconcileRange(_ range: TextRange, from other: any TextLayoutCollection) -> TextRange? {
      guard
        layouts.count == other.layouts.count,
        let start = reconcilePosition(range.start, from: other),
        let end = reconcilePosition(range.end, from: other)
      else {
        return nil
      }

      return TextRange(start: start, end: end)
    }

    @available(macOS 10.0, *)
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func nextWord(from position: TextPosition) -> TextPosition? {
      guard layouts.indices.contains(position.indexPath.layout) else {
        return nil
      }
      let layout = layouts[position.indexPath.layout]
      let characterIndex = localCharacterIndex(at: position)
      let nextCharacterIndex = layout.attributedString.nextWord(from: characterIndex)

      if nextCharacterIndex >= layout.attributedString.length {
        // try next layout
        guard position.indexPath.layout + 1 < layouts.endIndex else {
          return endPosition
        }

        return self.position(
          at: position.indexPath.layout + 1,
          localCharacterIndex: 0
        )
      }

      return self.position(
        at: position.indexPath.layout,
        localCharacterIndex: nextCharacterIndex
      )
    }

    @available(macOS 10.0, *)
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func previousWord(from position: TextPosition) -> TextPosition? {
      guard layouts.indices.contains(position.indexPath.layout) else {
        return nil
      }
      let layout = layouts[position.indexPath.layout]
      let characterIndex = localCharacterIndex(at: position)
      let previousCharacterIndex = layout.attributedString.previousWord(from: characterIndex)

      if previousCharacterIndex == 0 && characterIndex == 0 {
        // Try previous layout
        guard position.indexPath.layout > 0 else {
          return startPosition
        }

        let previousLayout = layouts[position.indexPath.layout - 1]

        guard
          let position = self.position(
            at: position.indexPath.layout - 1,
            localCharacterIndex: previousLayout.attributedString.length - 1
          )
        else {
          return nil
        }

        return previousWord(from: position)
      }

      return self.position(
        at: position.indexPath.layout,
        localCharacterIndex: previousCharacterIndex
      )
    }

    func blockStart(for position: TextPosition) -> TextPosition? {
      guard layouts.indices.contains(position.indexPath.layout) else {
        return nil
      }

      let start = TextPosition(
        indexPath: .init(layout: position.indexPath.layout),
        affinity: .downstream
      )

      // if we are already at the start, move to the previous block
      if position == start, position.indexPath.layout > 0 {
        return TextPosition(
          indexPath: .init(layout: position.indexPath.layout - 1),
          affinity: .downstream
        )
      }

      return start
    }

    func blockEnd(for position: TextPosition) -> TextPosition? {
      guard layouts.indices.contains(position.indexPath.layout) else {
        return nil
      }

      let layout = layouts[position.indexPath.layout]

      guard
        let line = layout.lines.last,
        let run = line.runs.last
      else {
        return nil
      }

      let end = TextPosition(
        indexPath: .init(
          runSlice: run.slices.endIndex - 1,
          run: line.runs.endIndex - 1,
          line: layout.lines.endIndex - 1,
          layout: position.indexPath.layout
        ),
        affinity: .upstream
      )

      // if we are already at the end, move to the next block
      if position == end, position.indexPath.layout + 1 < layouts.endIndex {
        let layout = layouts[position.indexPath.layout + 1]

        guard
          let line = layout.lines.last,
          let run = line.runs.last
        else {
          return nil
        }

        return TextPosition(
          indexPath: .init(
            runSlice: run.slices.endIndex - 1,
            run: line.runs.endIndex - 1,
            line: layout.lines.endIndex - 1,
            layout: position.indexPath.layout + 1
          ),
          affinity: .upstream
        )
      }

      return end
    }
  }

  extension TextLayoutCollection {
    fileprivate func reconcilePosition(
      _ position: TextPosition,
      from other: any TextLayoutCollection
    ) -> TextPosition? {
      self.position(
        at: position.indexPath.layout,
        localCharacterIndex: other.localCharacterIndex(at: position)
      )
    }
  }
  extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
      indices.contains(index) ? self[index] : nil
    }
  }
#endif
