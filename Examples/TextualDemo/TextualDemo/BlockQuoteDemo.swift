import SwiftUI
import Textual

struct BlockQuoteDemo: View {
  private let content = """
    > _“Everything was fine until it wasn’t”_ a realization usually followed by a
    > long stare at the screen and a quiet sigh :blobcatfacepalm:.

    > Debugging feels a lot like watching a mystery unfold in slow motion — popcorn
    > optional, confusion guaranteed :ablobcatpopcorn:.

    > At some point you stop fixing bugs and start negotiating with the code, hoping 
    > it accepts your terms :apusheencomputer:.

    > When the build fails for reasons unknown, it’s hard not to suspect foul play
    > :among_us:.
    """
  var body: some View {
    Form {
      Section {
        StructuredText(
          markdown: content,
          patternOptions: .init(emoji: .mastoEmoji)
        )
        .textual.textSelection(.enabled)
      } header: {
        Text("Default Style")
        Text("Text Selection Enabled")
      }
      Section("GitHub Style") {
        StructuredText(
          markdown: content,
          patternOptions: .init(emoji: .mastoEmoji)
        )
        .textual.structuredTextStyle(.gitHub)
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  BlockQuoteDemo()
}
