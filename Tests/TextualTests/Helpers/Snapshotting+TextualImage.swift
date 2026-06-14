#if os(iOS) && !targetEnvironment(macCatalyst)
  import SnapshotTesting
  import SwiftUI

  extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    @MainActor
    static func textualImage(layout: SwiftUISnapshotLayout) -> Snapshotting {
      .image(
        precision: 0.995,
        perceptualPrecision: 0.98,
        layout: layout
      )
    }
  }
#endif
