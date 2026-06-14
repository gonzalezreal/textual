#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct UnorderedListTests {
      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func hiearchicalSymbolList() {
        let view = StructuredText(
          markdown: """
            * Systems
              * FFF units
              * Great Underground Empire (Zork)
              * Potrzebie
                * Equals the thickness of Mad issue 26
                  * Developed by 19-year-old Donald E. Knuth
            """
        )
        .background(Color.guide)
        .padding(.horizontal)
        .textual.unorderedListMarker(.hierarchical(.disc, .circle, .square))

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }

      @Test func dashList() {
        let view = StructuredText(
          markdown: """
            * Systems
              * FFF units
              * Great Underground Empire (Zork)
              * Potrzebie
                * Equals the thickness of Mad issue 26
                  * Developed by 19-year-old Donald E. Knuth
            """
        )
        .background(Color.guide)
        .padding(.horizontal)
        .textual.unorderedListMarker(.dash)

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }

#endif
