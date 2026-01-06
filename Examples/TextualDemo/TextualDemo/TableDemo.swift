import SwiftUI
import Textual

struct TableDemo: View {
  private let content = """
    Sometimes it helps to step back and *observe the situation calmly*, especially 
    when the codebase feels larger than it should. You take a breath, open the 
    editor, and pretend everything is under control :annoyingdog:.

    To make sense of what’s going on, you jot down a quick overview.

    | Area            | Status        | Notes                              |
    |-----------------|---------------|------------------------------------|
    | Build           | Passing       | Surprisingly stable                |
    | Tests           | Mostly green  | One flaky test, as usual           |
    | Documentation   | In progress   | Started, enthusiasm pending        |
    | Refactor Plan   | Vague         | “We’ll know it when we see it”     |

    Looking at the table gives a comforting illusion of structure. Clearly, progress
    is being made — or at least *categorized*.

    Later on, as changes accumulate, a second table starts to tell a slightly different
    story :ablobthinking:.

    | Change Type     | Count | Confidence Level |
    |-----------------|-------|------------------|
    | Small tweaks    | 7     | High             |
    | “Quick fixes”   | 3     | Medium           |
    | Risky ideas     | 1     | Questionable     |

    At this point, the best course of action is obvious: commit what works, write a note
    for future you, and walk away while things are still calm. The code will still be
    here tomorrow, probably waiting patiently :awwwblob:.
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
  TableDemo()
}
