#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayoutCollection {
    @available(iOS, unavailable)
    @available(visionOS, unavailable)
    func wordRange(for position: TextPosition) -> TextRange? {
      guard layouts.indices.contains(position.indexPath.layout) else {
        return nil
      }
      let layout = layouts[position.indexPath.layout]
      let characterIndex = localCharacterIndex(at: position)

      guard
        let range = layout.wordRange(containing: characterIndex),
        let start = self.position(
          at: position.indexPath.layout,
          localCharacterIndex: range.lowerBound
        ),
        let end = self.position(
          at: position.indexPath.layout,
          localCharacterIndex: range.upperBound
        )
      else { return nil }

      return TextRange(start: start, end: end)
    }

    func blockRange(for position: TextPosition) -> TextRange? {
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

      return TextRange(
        start: .init(
          indexPath: .init(layout: position.indexPath.layout),
          affinity: .downstream
        ),
        end: .init(
          indexPath: .init(
            runSlice: run.slices.endIndex - 1,
            run: line.runs.endIndex - 1,
            line: layout.lines.endIndex - 1,
            layout: position.indexPath.layout
          ),
          affinity: .upstream
        )
      )
    }

    func clampRange(_ range: TextRange, layoutIndex: Int) -> TextRange? {
      guard layouts.indices.contains(layoutIndex) else {
        return nil
      }

      let layout = layouts[layoutIndex]

      guard
        let lastLine = layout.lines.last,
        let lastRun = lastLine.runs.last
      else {
        return nil
      }

      let start = TextPosition(
        indexPath: .init(layout: layoutIndex),
        affinity: .downstream
      )
      let end = TextPosition(
        indexPath: .init(
          runSlice: lastRun.slices.endIndex - 1,
          run: lastLine.runs.endIndex - 1,
          line: layout.lines.endIndex - 1,
          layout: layoutIndex
        ),
        affinity: .upstream
      )

      guard range.end > start && range.start < end else {
        return nil
      }

      return TextRange(
        start: Swift.max(range.start, start),
        end: Swift.min(range.end, end)
      )
    }
  }
#endif
