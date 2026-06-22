import SwiftUI

// MARK: - Overview
//
// `AttachmentView` draws attachment bodies at the positions reported by SwiftUI's `Text.Layout`.
//
// The `Text` pipeline reserves space for attachments using placeholders; the overlay draws the
// real SwiftUI views on top of those placeholders. Drawing uses a `Canvas` so attachment views can
// be resolved once as symbols and efficiently drawn into each run's `typographicBounds`.
//
// Selection integration:
// On macOS, when text selection is enabled, object-style attachments are dimmed when they fall
// inside the selected range. Inline-style attachments (for example, emoji) are not dimmed.

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct AttachmentView: View {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
  #endif
  private let attachments: Set<AnyAttachment>
  private let origin: CGPoint
  private let layout: Text.Layout

  init(
    attachments: Set<AnyAttachment>,
    origin: CGPoint,
    layout: Text.Layout
  ) {
    self.attachments = attachments
    self.origin = origin
    self.layout = layout
  }

  var body: some View {
    Canvas { context, _ in
      context.translateBy(x: origin.x, y: origin.y)
      for (lineIndex, line) in zip(layout.indices, layout) {
        for (runIndex, run) in zip(line.indices, line) {
          guard
            let attachment = run.attachment,
            let symbol = context.resolveSymbol(id: attachment)
          else {
            continue
          }

          context.opacity = opacity(
            for: attachment,
            lineIndex: lineIndex,
            runIndex: runIndex
          )

          context.draw(symbol, in: run.typographicBounds.rect)
        }
      }
    } symbols: {
      ForEach(Array(attachments), id: \.self) { attachment in
        attachment.body
          .tag(attachment)
      }
    }
  }

  private func opacity(
    for attachment: AnyAttachment,
    lineIndex: Int,
    runIndex: Int
  ) -> CGFloat {
    #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
      guard
        attachment.selectionStyle == .object,
        let textSelectionModel,
        let selectedRange = textSelectionModel.selectedRange,
        let layoutIndex = textSelectionModel.layoutIndex(of: layout)
      else {
        return 1
      }

      let position = TextPosition(
        indexPath: .init(run: runIndex, line: lineIndex, layout: layoutIndex),
        affinity: .downstream
      )

      return selectedRange.contains(position) ? 0.5 : 1
    #else
      1
    #endif
  }
}
