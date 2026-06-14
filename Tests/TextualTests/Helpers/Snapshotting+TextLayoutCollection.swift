#if TEXTUAL_ENABLE_TEXT_SELECTION && os(iOS) && !targetEnvironment(macCatalyst)
  import SnapshotTesting
  import SwiftUI

  @testable import Textual

  extension Snapshotting where Value: SwiftUI.View, Format == String {
    @MainActor
    static func textLayoutCollection(config: ViewImageConfig = .iPhoneSe) -> Snapshotting {
      return Snapshotting<CodableTextLayoutCollection, String>.json
        .asyncPullback { (view: Value) -> Async<CodableTextLayoutCollection> in
          // Capture layout from view
          var capturedLayoutCollection: (any TextLayoutCollection)?
          let viewWithCapture = view.overlayTextLayoutCollection { layoutCollection in
            capturedLayoutCollection = layoutCollection
            return Color.clear
          }

          // Use image strategy to render and trigger layout capture
          let imageStrategy = Snapshotting<AnyView, UIImage>.image(layout: .device(config: config))
          let asyncImage = imageStrategy.snapshot(AnyView(viewWithCapture))

          return asyncImage.map { _ in
            guard let capturedLayoutCollection else {
              preconditionFailure("Failed to capture layout data")
            }
            return CodableTextLayoutCollection(capturedLayoutCollection)
          }
        }
    }
  }
#endif
