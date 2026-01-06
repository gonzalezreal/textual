import SwiftUI
import Textual

struct StructuredTextDemo: View {
  @State private var wrapCode = false

  private let content = """
    # Debugging the Navigation Stack :doge:

    Yesterday's feature branch looked solid—clean tests, smooth PR review, merged to main. This morning? The entire navigation stack decided to throw a party, and we weren't invited :confused_dog:.

    ## The Problem

    > After merging PR #347, users reported that tapping "Back" from the detail view would sometimes navigate to a completely random screen. One user ended up in Settings while trying to return to their inbox. Another saw the onboarding flow. Creative, but not ideal.

    Here's what we knew going in:

    - The issue only appeared **after** the state restoration changes
    - It happened _inconsistently_—maybe 1 in 5 back navigations
    - The stack trace was... let's call it "unhelpful" :sad_dog:

    ![Navigation chaos visualization](https://picsum.photos/seed/navigation/400/250)

    ## Investigation Steps

    The debugging process went something like this:

    1. **Reproduce locally** :dogroll:
       - Spent two hours clicking Back repeatedly
       - Finally caught it in the act
    2. **Add logging everywhere**
       - Navigation events
       - State changes
       - View lifecycle
    3. **Review the diff**
       - The PR changed 47 files
       - Most were innocent
       - One was... not

    ### The Breakthrough

    Buried in `NavigationStateManager.swift`, we found this beauty:

    ```swift
    func restoreNavigationStack(_ stack: [Route]) {
        // FIXME: This doesn't handle concurrent updates
        for route in stack {
            navigationPath.append(route)
        }
    }
    ```

    That `FIXME` comment? It was trying to tell us something :confused_dog:.

    ## The Fix

    Turns out we had a **classic race condition**. Two async operations trying to restore state simultaneously, each appending to the navigation path without coordination. The solution was simpler than expected:

    ```swift
    actor NavigationStateManager {
        func restoreNavigationStack(_ stack: [Route]) async {
            await MainActor.run {
                navigationPath = NavigationPath(stack)
            }
        }
    }
    ```

    By making the manager an `actor` and setting the entire path atomically instead of appending item-by-item, we eliminated the race. No more navigation roulette :doge:.

    ## Results

    | Metric | Before | After |
    |--------|--------|-------|
    | Bug reports | 47 | 0 |
    | Random navigations | ~20% | 0% |
    | User confusion | High | None |
    | Developer relief | Low | :dogluv: |

    ## Lessons Learned

    The usual suspects:

    - **Read the comments**: That `FIXME` was a warning
    - **Race conditions are sneaky**: Especially in navigation code
    - **Atomic operations matter**: Append-in-loop vs set-entire-path makes a difference
    - **Test async code thoroughly**: Our tests were all synchronous

    The fix shipped in v2.3.1 this afternoon. Users are happy, the navigation stack is boring again (in a good way), and we can finally move on to the _next_ mysterious bug :dogroll:.

    ---

    *Debugging complete. Time for coffee.*
    """

  var body: some View {
    Form {
      Toggle("Wrap Code Blocks", isOn: $wrapCode)
      StructuredText(
        markdown: content,
        patternOptions: .init(emoji: .mastoEmoji)
      )
      .textual.textSelection(.enabled)
      .textual.overflowMode(self.wrapCode ? .wrap : .scroll)
    }
    .formStyle(.grouped)
  }
}

#Preview {
  StructuredTextDemo()
}
