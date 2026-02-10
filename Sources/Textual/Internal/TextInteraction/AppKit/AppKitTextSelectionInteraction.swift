#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextSelectionInteraction` presents the platform-specific text selection overlay for macOS.
  //
  // The modifier receives a `TextSelectionModel` and places it in the environment so selection highlights
  // and attachment dimming can access it. An overlay hosts `AppKitTextInteractionOverlay`, which wraps an
  // `NSView` that handles selection gestures and context menus. The modifier also manages cursor updates,
  // switching between I-beam and pointing hand based on hover position over text or links.

  typealias PlatformTextSelectionInteraction = AppKitTextSelectionInteraction

  struct AppKitTextSelectionInteraction: ViewModifier {
    @State private var cursorPushed = false

    private let model: TextSelectionModel

    init(model: TextSelectionModel) {
      self.model = model
    }

    func body(content: Content) -> some View {
      content
        // We need the selection model at text fragment level for the
        // text selection background and selected attachment dimming
        .environment(model)
        .overlayPreferenceValue(OverflowFrameKey.self) { frames in
          AppKitTextInteractionOverlay(model: model, overflowFrames: frames)
            .onContinuousHover { phase in
              updateCursor(for: phase, model: model)
            }
        }
    }

    private func updateCursor(for phase: HoverPhase, model: TextSelectionModel) {
      switch phase {
      case .active(let location):
        let cursor =
          model.url(for: location) != nil
          ? NSCursor.pointingHand
          : NSCursor.iBeam
        if !cursorPushed {
          cursor.push()
          cursorPushed = true
        } else {
          cursor.set()
        }
      case .ended:
        if cursorPushed {
          NSCursor.pop()
          cursorPushed = false
        }
      }
    }
  }
#endif
