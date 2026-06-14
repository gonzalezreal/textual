#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct CodeBlockTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func codeBlock() {
        let view = StructuredText(
          markdown: """
            The sky above the port was the color of television, tuned to a dead channel.

            ```swift
            struct Sightseeing: Activity {
                func perform(with sloth: inout Sloth) -> Speed {
                    sloth.energyLevel -= 10
                    return .slow
                }
            }
            ```

            It was a bright cold day in April, and the clocks were striking thirteen.
            """
        )
        .padding(.horizontal)

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }
#endif
