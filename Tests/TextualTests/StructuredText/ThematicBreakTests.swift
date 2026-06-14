#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct ThematicBreakTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func defaultStyle() {
        let view = StructuredText(
          markdown: """
            # SwiftUI

            Declare the user interface and behavior for your app
            on every platform.

            ---

            ## Overview

            SwiftUI provides views, controls, and layout structures
            for declaring your app’s user interface.

            ---

            ― From Apple Developer Documentation
            """
        )
        .background(Color.guide)
        .padding(.horizontal)

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }
#endif
