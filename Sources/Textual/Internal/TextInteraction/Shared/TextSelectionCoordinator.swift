import SwiftUI

// MARK: - Overview
//
// `TextSelectionCoordinator` ensures there’s at most one active selection across a view subtree.
//
// Selection can be driven by multiple independent overlays. For example, `Overflow`-backed
// scrollable regions install their own interaction views so selection works locally inside the
// scroll view, while the surrounding content can still be selectable.
//
// Each `TextSelectionModel` registers with a shared coordinator. When one model becomes selected,
// the coordinator clears selection in the others, preventing multiple active selections across
// local and non-scrollable regions.

#if TEXTUAL_ENABLE_TEXT_SELECTION
  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  @Observable
  final class TextSelectionCoordinator {
    private var models: [WeakBox<TextSelectionModel>] = []

    func register(_ model: TextSelectionModel) {
      models.append(WeakBox(model))
      compact()
    }

    func modelDidSelectText(_ model: TextSelectionModel) {
      // Clear selection in the other models
      for weakModel in models where weakModel.wrapped !== model {
        weakModel.wrapped?.selectedRange = nil
      }
      compact()
    }

    private func compact() {
      models.removeAll {
        $0.wrapped == nil
      }
    }
  }
#endif

struct TextSelectionCoordination: ViewModifier {
  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
        content.modifier(TextSelectionCoordinationBody())
      } else {
        content
      }
    #else
      content
    #endif
  }
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  private struct TextSelectionCoordinationBody: ViewModifier {
    @State private var coordinator = TextSelectionCoordinator()

    func body(content: Content) -> some View {
      content.environment(coordinator)
    }
  }
#endif
