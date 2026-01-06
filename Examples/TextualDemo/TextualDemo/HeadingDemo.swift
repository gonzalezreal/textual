import SwiftUI
import Textual

struct HeadingDemo: View {
  private let content = """
    # A Calm Start :ablobwave:
    Everything looks peaceful, the editor is open, and confidence is inexplicably high.

    ## Then Reality Kicks In
    The compiler has opinions, most of them unsolicited.

    ### Debug Mode Activated :ablobthinking:
    You stare at the code long enough, hoping it blinks first.

    #### A Small Victory
    One warning disappears and morale improves slightly.

    ##### Coffee-Driven Optimism :ablobcatcoffee:
    Surely this change won’t break anything else.

    ###### Time to Commit :100_valid:
    You hit save, push the branch, and decide this is a problem for future you.
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
      }
      .textual.structuredTextStyle(.gitHub)
    }
    .formStyle(.grouped)
  }
}

#Preview {
  HeadingDemo()
}
