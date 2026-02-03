import SwiftUI

// MARK: - Overview
//
// `AttachmentView` draws attachment bodies at the positions reported by SwiftUI's `Text.Layout`.
//
// The `Text` pipeline reserves space for attachments using placeholders; the overlay draws the
// real SwiftUI views on top of those placeholders.
//
// Rendering Modes:
// - `.canvas` (default): Views are resolved once as Canvas symbols and efficiently drawn into
//   each run's `typographicBounds`. Attachments are static but performant.
// - `.interactive`: Views are positioned directly as live SwiftUI views, enabling full
//   interactivity (buttons, gestures, state updates) at a slight performance cost.
//
// Selection integration:
// On macOS, when text selection is enabled, object-style attachments are dimmed when they fall
// inside the selected range. Inline-style attachments (for example, emoji) are not dimmed.

struct AttachmentView: View {
  #if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
  #endif
  @Environment(\.attachmentRenderingMode) private var renderingMode

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
    switch renderingMode {
    case .canvas:
      canvasRendering
    case .interactive:
      interactiveRendering
    }
  }

  // MARK: - Canvas Rendering (Original)

  private var canvasRendering: some View {
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

  // MARK: - Interactive Rendering (New)

  private var interactiveRendering: some View {
    ZStack(alignment: .topLeading) {
      ForEach(attachmentPositions) { position in
        position.attachment.body
          .opacity(position.opacity)
          .frame(width: position.bounds.width, height: position.bounds.height)
          .position(
            x: origin.x + position.bounds.midX,
            y: origin.y + position.bounds.midY
          )
      }
    }
  }

  private struct AttachmentPosition: Identifiable {
    let id = UUID()
    let attachment: AnyAttachment
    let bounds: CGRect
    let opacity: CGFloat
  }

  private var attachmentPositions: [AttachmentPosition] {
    var positions: [AttachmentPosition] = []

    for (lineIndex, line) in zip(layout.indices, layout) {
      for (runIndex, run) in zip(line.indices, line) {
        guard let attachment = run.attachment else {
          continue
        }

        let opacity = opacity(
          for: attachment,
          lineIndex: lineIndex,
          runIndex: runIndex
        )

        positions.append(
          AttachmentPosition(
            attachment: attachment,
            bounds: run.typographicBounds.rect,
            opacity: opacity
          )
        )
      }
    }

    return positions
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
