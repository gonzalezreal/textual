#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import SnapshotTesting

  import Textual

  extension StructuredText {
    @MainActor
    struct BlockQuoteTests {
      private struct IndentationLevelBlockQuoteStyle: BlockQuoteStyle {
        private let colors: [Color]

        init(colors: Color...) {
          self.colors = colors
        }

        func makeBody(configuration: Configuration) -> some View {
          DefaultBlockQuoteStyle(
            backgroundColor: .init(
              colors[(configuration.indentationLevel - 1) % colors.count]
            ),
            borderColor: .init(.secondary)
          )
          .makeBody(configuration: configuration)
        }
      }

      private let layout = SwiftUISnapshotLayout.device(config: .iPhone8)

      @Test func defaultStyle() {
        let view = StructuredText(
          markdown: """
            > “Well, art is art, isn't it? Still,
            > on the other hand, water is water!
            > And east is east and west is west and
            > if you take cranberries and stew them
            > like applesauce they taste much more
            > like prunes than rhubarb does. Now,
            > uh... now you tell me what you
            > know.”
            > > “I sent the club a wire stating,
            > > **PLEASE ACCEPT MY RESIGNATION. I DON'T
            > > WANT TO BELONG TO ANY CLUB THAT WILL ACCEPT ME AS A MEMBER**.”
            > > > “Outside of a dog, a book is man's best friend. Inside of a
            > > > dog it's too dark to read.”

            ― Groucho Marx                    
            """
        )
        .background(Color.guide)
        .padding(.horizontal)

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }

      @Test func indentationLevel() {
        let view = StructuredText(
          markdown: """
            > “Well, art is art, isn't it? Still,
            > on the other hand, water is water!
            > And east is east and west is west and
            > if you take cranberries and stew them
            > like applesauce they taste much more
            > like prunes than rhubarb does. Now,
            > uh... now you tell me what you
            > know.”
            > > “I sent the club a wire stating,
            > > **PLEASE ACCEPT MY RESIGNATION. I DON'T
            > > WANT TO BELONG TO ANY CLUB THAT WILL ACCEPT ME AS A MEMBER**.”
            > > > “Outside of a dog, a book is man's best friend. Inside of a
            > > > dog it's too dark to read.”

            ― Groucho Marx                    
            """
        )
        .background(Color.guide)
        .padding(.horizontal)
        .textual.blockQuoteStyle(IndentationLevelBlockQuoteStyle(colors: .green, .mint, .teal))

        assertSnapshot(of: view, as: .textualImage(layout: layout))
      }
    }
  }
#endif
