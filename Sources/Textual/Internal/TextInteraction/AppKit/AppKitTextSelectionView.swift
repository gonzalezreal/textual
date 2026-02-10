#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionView` renders selection highlights for a single `Text.Layout`.
  //
  // Each text fragment provides its own resolved layout and origin. The view reads the shared
  // `TextSelectionModel` from the environment, computes selection rectangles for the current
  // range within this layout, and paints them in a `Canvas` behind the text.

  struct AppKitTextSelectionView: View {
    @Environment(TextSelectionModel.self) private var textSelectionModel: TextSelectionModel?
    @State private var selectionRects: [TextSelectionRect] = []

    private let layout: Text.Layout
    private let origin: CGPoint

    init(layout: Text.Layout, origin: CGPoint) {
      self.layout = layout
      self.origin = origin
    }

    var body: some View {
      Group {
        if selectionRects.isEmpty {
          Color.clear
        } else {
          Canvas { context, _ in
            context.translateBy(x: origin.x, y: origin.y)
            for selectionRect in selectionRects {
              context.fill(
                Path(selectionRect.rect.integral),
                with: .color(.init(nsColor: .selectedTextBackgroundColor))
              )
            }
          }
        }
      }
      .onChange(of: textSelectionModel?.selectedRange, initial: true, updateSelectionRects)
      .onChange(of: layout, initial: true, updateSelectionRects)
    }

    private func updateSelectionRects() {
      if let textSelectionModel,
        let selectedRange = textSelectionModel.selectedRange
      {
        selectionRects = textSelectionModel.selectionRects(for: selectedRange, layout: layout)
      } else {
        selectionRects = []
      }
    }
  }
#endif
