import SwiftUI

// MARK: - Overview
//
// `TextSelectionInteraction` manages the text selection model lifecycle for multiple `Text` fragments.
//
// Selection is opt-in through the `textSelection` environment value. When enabled, the modifier
// observes text layout changes via `overlayTextLayoutCollection` and creates or updates a
// `TextSelectionModel`. The model is then passed to the platform-specific implementation
// (`PlatformTextSelectionInteraction`), which presents the appropriate selection UI for macOS
// or iOS. This separation keeps model management in shared code while platform interactions
// remain independent.

struct TextSelectionInteraction: ViewModifier {
  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if #available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *) {
        content.modifier(TextSelectionInteractionBody())
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
  private struct TextSelectionInteractionBody: ViewModifier {
    @Environment(\.textSelection) private var textSelection
    @Environment(TextSelectionCoordinator.self) private var coordinator: TextSelectionCoordinator?

    @State private var model = TextSelectionModel()

    func body(content: Content) -> some View {
      if textSelection.allowsSelection {
        content
          .overlayTextLayoutCollection { layoutCollection in
            Color.clear
              .onChange(of: AnyTextLayoutCollection(layoutCollection), initial: true) {
                model.setCoordinator(coordinator)
                model.setLayoutCollection(layoutCollection)
              }
          }
          .modifier(PlatformTextSelectionInteraction(model: model))
      } else {
        content
      }
    }
  }

  private struct TextSelectionKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: any TextSelectability.Type = DisabledTextSelectability.self
  }

  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @usableFromInline
    var textSelection: any TextSelectability.Type {
      get { self[TextSelectionKey.self] }
      set { self[TextSelectionKey.self] = newValue }
    }
  }
#endif
