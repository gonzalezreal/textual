#if TEXTUAL_ENABLE_TEXT_SELECTION
  import Foundation

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayoutCollection {
    func indexPathsForRunSlices(in range: TextRange) -> some Sequence<IndexPath> {
      IndexPathSequence(
        range: range,
        next: self.indexPathForRunSlice(after:),
        previous: self.indexPathForRunSlice(before:)
      )
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayoutCollection {
    fileprivate func indexPathForRunSlice(after indexPath: IndexPath) -> IndexPath? {
      let layout = layouts[indexPath.layout]
      let line = layout.lines[indexPath.line]
      let run = line.runs[indexPath.run]

      if indexPath.runSlice + 1 < run.slices.count {
        return IndexPath(
          runSlice: indexPath.runSlice + 1,
          run: indexPath.run,
          line: indexPath.line,
          layout: indexPath.layout
        )
      }

      if indexPath.run + 1 < line.runs.count {
        return IndexPath(
          run: indexPath.run + 1,
          line: indexPath.line,
          layout: indexPath.layout
        )
      }

      if indexPath.line + 1 < layout.lines.count {
        return IndexPath(
          line: indexPath.line + 1,
          layout: indexPath.layout
        )
      }

      if indexPath.layout + 1 < layouts.count {
        return IndexPath(layout: indexPath.layout + 1)
      }

      return nil
    }

    fileprivate func indexPathForRunSlice(before indexPath: IndexPath) -> IndexPath? {
      if indexPath.runSlice > 0 {
        return IndexPath(
          runSlice: indexPath.runSlice - 1,
          run: indexPath.run,
          line: indexPath.line,
          layout: indexPath.layout
        )
      }

      if indexPath.run > 0 {
        let previousRun = layouts[indexPath.layout].lines[indexPath.line].runs[indexPath.run - 1]
        return IndexPath(
          runSlice: previousRun.slices.endIndex - 1,
          run: indexPath.run - 1,
          line: indexPath.line,
          layout: indexPath.layout
        )
      }

      if indexPath.line > 0 {
        let previousLine = layouts[indexPath.layout].lines[indexPath.line - 1]
        let lastRunIndex = previousLine.runs.endIndex - 1
        let lastRun = previousLine.runs[lastRunIndex]

        return IndexPath(
          runSlice: lastRun.slices.endIndex - 1,
          run: lastRunIndex,
          line: indexPath.line - 1,
          layout: indexPath.layout
        )
      }

      if indexPath.layout > 0 {
        let previousLayout = layouts[indexPath.layout - 1]
        let lastLineIndex = previousLayout.lines.endIndex - 1
        let lastLine = previousLayout.lines[lastLineIndex]
        let lastRunIndex = lastLine.runs.endIndex - 1
        let lastRun = lastLine.runs[lastRunIndex]
        return IndexPath(
          runSlice: lastRun.slices.endIndex - 1,
          run: lastRunIndex,
          line: lastLineIndex,
          layout: indexPath.layout - 1
        )
      }

      return nil
    }
  }
#endif
