#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct HeadingTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func defaultStyle() {
        let view = StructuredText(
          markdown: """
            # Heading 1
            The sky above the port was the color of television, tuned to a dead channel.
            ## Heading 2
            The sky above the port was the color of television, tuned to a dead channel.
            ### Heading 3
            The sky above the port was the color of television, tuned to a dead channel.
            #### Heading 4
            The sky above the port was the color of television, tuned to a dead channel.
            ##### Heading 5
            The sky above the port was the color of television, tuned to a dead channel.
            ###### Heading 6
            The sky above the port was the color of television, tuned to a dead channel.
            """
        )
        .background(Color.guide)
        .padding(.horizontal)
        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }

      @Test func inlines() {
        let view = StructuredText(
          markdown: """
            # Put some *emphasis* to it
            ## Using `StructuredText`
            ## This is ~~wrong~~
            ## Go to https://example.com
            """
        )
        .background(Color.guide)
        .padding(.horizontal)
        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }
#endif
