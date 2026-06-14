#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct TableTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func table() {
        let view = StructuredText(
          markdown: """
            The sky above the port was the color of television, tuned to a dead channel.

            | Command | Description |
            | --- | --- |
            | `git status` | List all new or modified files |
            | `git diff` | Show file differences that haven't been staged |

            It was a bright cold day in April, and the clocks were striking thirteen.
            """
        )
        .padding(.horizontal)

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }

      @Test func tableAlignment() {
        let view = StructuredText(
          markdown: """
            The sky above the port was the color of television, tuned to a dead channel.

            | Leading    | Center     | Trailing   |
            | :---       |    :---:   |       ---: |
            | `git status` | `git status` | `git status` |
            | `git diff`   | `git diff`   | `git diff`   |

            It was a bright cold day in April, and the clocks were striking thirteen.
            """
        )
        .padding(.horizontal)

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }
#endif
