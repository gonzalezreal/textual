import SwiftUI
import Textual

struct TableDemo: View {
  @State private var relativeWidth: CGFloat = 2.1

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
  private let overflowContent = """
    When the status board grows beyond the comfort of the sidebar, it’s time for a wider view.

    | Feature Area     | Owner            | Status       | Notes                                                                 |
    |------------------|------------------|--------------|-----------------------------------------------------------------------|
    | Attachments      | Casey            | In progress  | Needs caching strategy; large emoji sets are still slow to resolve.   |
    | Selection        | Drew             | Investigating| Selection handles are jittery with nested lists and inline links.     |
    | Rendering        | Jae              | Stable       | Layout passes are predictable, but long cells should wrap cleanly.    |

    After a few iterations, priorities shift and a more detailed breakdown appears.

    | Milestone            | Target Date | Dependency        | Notes                                                  |
    |----------------------|-------------|-------------------|--------------------------------------------------------|
    | Rendering polish     | Sep 18      | Table overlays    | Needs scrollable headers without losing alignment.     |
    | Selection fixes      | Sep 25      | Text layout       | Requires stable geometry on fast resize changes.       |
    | Attachment pipeline  | Oct 02      | Caching strategy  | Large emoji sets should avoid repeated decode work.    |
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
      Section {
        HStack {
          Text("Relative Width")
          Slider(value: $relativeWidth, in: 1...3)
        }
        StructuredText(
          markdown: overflowContent,
          patternOptions: .init(emoji: .mastoEmoji)
        )
      } header: {
        Text("Overflow Style")
        Text("Horizontal Scroll")
      }
      .textual.tableStyle(.overflow(relativeWidth: relativeWidth))
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
