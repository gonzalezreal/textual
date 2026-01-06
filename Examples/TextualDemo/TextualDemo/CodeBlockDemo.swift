import SwiftUI
import Textual

struct CodeBlockDemo: View {
  @State private var wrapCode = false

  var body: some View {
    Form {
      Toggle("Wrap Code Blocks", isOn: $wrapCode)
      Section {
        StructuredText(
          markdown: """
            Sometimes you open the project feeling confident, convinced that *this time* it will be
            straightforward. The files load, the build starts, and optimism briefly wins :annoyingdog:.

            Then you remember why you left a note to yourself.

            ```swift
            // TODO: clean this up later
            // (future me will definitely understand this)

            func makeItWork(_ value: Int?) -> Int {
                guard let value else {
                    return 42
                }

                return value * 2
            }
            ```

            You read the code twice, nod slowly, and realize the logic makes sense, even if the naming
            choices feel a bit feral :annoying_dog_hole:.

            ```bash
            $ swift test
            ✔ Test Suite 'All tests' passed
            ✔ Executed 128 tests, with 0 failures
            ```

            Encouraged by this fragile success, you refactor just a little, tell yourself not to chase
            perfection, and prepare to commit like a loyal but slightly nervous companion :awwwblob:.

            ```
            commit 3f2a9c1
            Author: you
            Message: "Minor cleanup, no functional changes (famous last words)"
            ```

            At this point, the code behaves, the build is quiet, and you decide not to push your luck.
            Tomorrow is another walk.
            """,
          patternOptions: .init(emoji: .mastoEmoji)
        )
        .textual.textSelection(.enabled)
        .textual.overflowMode(self.wrapCode ? .wrap : .scroll)
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  CodeBlockDemo()
}
