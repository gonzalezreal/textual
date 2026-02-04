import SwiftUI
import Textual

struct InlineTextDemo: View {
  var body: some View {
    Form {
      Section("Images") {
        InlineText(
          markdown: """
            This is a *lighthearted* but **perfectly serious** paragraph where `inline code` lives \
            happily alongside ~~a terrible idea~~ a better one, a [useful link](https://example.com), \
            and a bit of _extra emphasis_ just for style. To keep things interesting without overdoing \
            it, here’s a completely random image that adapts to the container width:

            ![Random image](https://picsum.photos/seed/textual/400/250)
            """
        )
        .textual.textSelection(.enabled)
      }
      Section("Custom Emoji") {
        InlineText(
          markdown: """
            **Working late on the new feature** has been surprisingly fun—_even when the build \
            fails_ :confused_dog:, a quick refactor usually gets things back on track :doge:, \
            and when it doesn’t, I just roll with it :dogroll: until the solution finally \
            clicks (though sometimes I still end up a bit **:confused_dog:** or _small \
            :confused_dog:_... plus another :confused_dog: for good measure).
            """,
          syntaxExtensions: [.emoji(.mastoEmoji)]
        )
        .textual.inlineStyle(
          InlineStyle()
            .strong(.bold, .fontScale(1.3))
            .emphasis(.italic, .fontScale(0.85))
        )
      }
      Section("Custom Inline Style") {
        InlineText(
          markdown: """
            This is a *lighthearted* but **perfectly serious** paragraph where `inline code` lives \
            happily alongside ~~a terrible idea~~ a better one, a [useful link](https://example.com), \
            and a bit of _extra emphasis_ just for style.
            """
        )
        .textual.inlineStyle(.custom)
      }
      Section("Interactive Pill Attachments") {
        PillDemoView()
      }
    }
    .formStyle(.grouped)
  }
}

// MARK: - Pill Demo View

struct PillDemoView: View {
  var body: some View {
    VStack(spacing: 16) {
      // Test 1: Regular link (baseline - we know this works)
      InlineText(markdown: "Tap this [regular link](https://example.com) to test.")
        .environment(\.openURL, OpenURLAction { url in
          print("🔗 Regular link tapped: \(url)")
          return .handled
        })

      // Test 2: Custom URL scheme for citations
      InlineText(markdown: "This is text with [PubMed](citation://0) and [NICE](citation://1) inline.")
        .environment(\.openURL, OpenURLAction { url in
          print("🎯 Link tapped: \(url)")
          if url.scheme == "citation" {
            print("   ✅ Citation link detected!")
            if let host = url.host, let index = Int(host) {
              print("   📍 Citation index: \(index)")
            }
            return .handled
          }
          return .systemAction
        })
    }
    .padding()
  }
}

// MARK: - Pill Demo Parser

@MainActor
struct PillDemoParser: MarkupParser {
  func attributedString(for input: String) throws -> AttributedString {
    var text = AttributedString("This paragraph demonstrates inline ")

    // Add first pill
    var pill1 = AttributedString("PubMed")
    pill1.textual.attachment = AnyAttachment(
      PillAttachment(text: "PubMed", onTap: {
        print("Tapped PubMed pill!")
      })
    )
    text.append(pill1)

    text.append(AttributedString(" and "))

    // Add second pill
    var pill2 = AttributedString("NICE")
    pill2.textual.attachment = AnyAttachment(
      PillAttachment(text: "NICE", onTap: {
        print("Tapped NICE pill!")
      })
    )
    text.append(pill2)

    text.append(AttributedString(" interactive pill attachments flowing naturally with the text, even when the text wraps to multiple lines."))

    return text
  }
}

extension InlineStyle {
  fileprivate static var custom: InlineStyle {
    InlineStyle()
      .code(
        .monospaced,
        .fontScale(0.85),
        .backgroundColor(.purple),
        .foregroundColor(.white)
      )
      .emphasis(.italic, .underlineStyle(.single))
      .strikethrough(.foregroundColor(.secondary))
      .link(.foregroundColor(.purple), .underlineStyle(.init(pattern: .dot)))
  }
}

#Preview {
  InlineTextDemo()
}
