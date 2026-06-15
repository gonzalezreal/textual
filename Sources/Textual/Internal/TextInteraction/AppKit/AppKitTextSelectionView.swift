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

    private let layout: Text.Layout
    private let origin: CGPoint

    init(layout: Text.Layout, origin: CGPoint) {
      self.layout = layout
      self.origin = origin
    }

    var body: some View {
      let selectionRects = self.selectionRects
      return Group {
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
    }

    /// Selection rectangles for the current range within this layout.
    ///
    /// Derived in `body` rather than stored in `@State` and seeded from an
    /// `onChange(initial: true)`: that initial action wrote state during the first
    /// view update, which SwiftUI flags ("Modifying state during view update", and
    /// previously "tried to update multiple times per frame" when both the
    /// `selectedRange` and `layout` handlers fired on the same frame). As an
    /// `@Observable`-tracked computation it still recomputes whenever the selected
    /// range or `layout` changes, with no state mutation.
    private var selectionRects: [TextSelectionRect] {
      guard let textSelectionModel, let selectedRange = textSelectionModel.selectedRange else {
        return []
      }
      return textSelectionModel.selectionRects(for: selectedRange, layout: layout)
    }
  }
#endif
