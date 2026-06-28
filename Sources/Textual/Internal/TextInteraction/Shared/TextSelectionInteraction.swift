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
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.textSelection) private var textSelection
    @Environment(TextSelectionCoordinator.self) private var coordinator: TextSelectionCoordinator?

    @State private var model = TextSelectionModel()
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if textSelection.allowsSelection {
        content
          .overlayTextLayoutCollection { layoutCollection in
            // Deliver the layout collection to the selection model through a
            // representable's update path rather than `onChange`. For short content
            // (a fragment whose text fits without scrolling) all of the progressive
            // `Text.LayoutKey` preference updates land in a SINGLE SwiftUI frame.
            // `onChange` coalesces same-frame repeats — the "onChange(of:) action
            // tried to update multiple times per frame" guard — and drops the
            // populated value, so the model is left on an empty layout collection:
            // `closestPosition` then returns nil and a drag-select never starts.
            // (Deferring the work inside that `onChange` does not help — the dropped
            // action never runs to schedule it.) A representable's `updateNSView` /
            // `updateUIView` runs on every update cycle with the latest inputs and is
            // not subject to that drop, so the final populated collection always
            // reaches the model. Taller content settled across multiple frames and so
            // happened to work even with `onChange`.
            TextLayoutModelUpdater(
              model: model,
              coordinator: coordinator,
              layoutCollection: layoutCollection
            )
          }
          .modifier(PlatformTextSelectionInteraction(model: model))
      } else {
        content
      }
    #else
      content
    #endif
  }
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @usableFromInline
    @Entry var textSelection: any TextSelectability.Type = DisabledTextSelectability.self
  }

  // Pushes the latest `TextLayoutCollection` into the selection model via a
  // representable's update path (see `TextSelectionInteraction.body` for why
  // `onChange` is insufficient for single-frame layouts). The hosted platform view
  // is a non-interactive passthrough — it exists only to receive `update*View`; it
  // never participates in hit-testing, so the real selection overlay and any excluded
  // scroll regions still get their events. Writing the model's `@ObservationIgnored`
  // `layoutCollection`/`coordinator` here does not trigger SwiftUI invalidation.
  #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    import AppKit

    private struct TextLayoutModelUpdater: NSViewRepresentable {
      let model: TextSelectionModel
      let coordinator: TextSelectionCoordinator?
      let layoutCollection: any TextLayoutCollection

      func makeNSView(context: Context) -> PassthroughNSView {
        applyToModel()
        return PassthroughNSView()
      }

      func updateNSView(_ nsView: PassthroughNSView, context: Context) {
        applyToModel()
      }

      private func applyToModel() {
        model.setCoordinator(coordinator)
        model.setLayoutCollection(layoutCollection)
      }
    }

    private final class PassthroughNSView: NSView {
      override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
  #elseif canImport(UIKit)
    import UIKit

    private struct TextLayoutModelUpdater: UIViewRepresentable {
      let model: TextSelectionModel
      let coordinator: TextSelectionCoordinator?
      let layoutCollection: any TextLayoutCollection

      func makeUIView(context: Context) -> PassthroughUIView {
        applyToModel()
        return PassthroughUIView()
      }

      func updateUIView(_ uiView: PassthroughUIView, context: Context) {
        applyToModel()
      }

      private func applyToModel() {
        model.setCoordinator(coordinator)
        model.setLayoutCollection(layoutCollection)
      }
    }

    private final class PassthroughUIView: UIView {
      override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
    }
  #endif
#endif
