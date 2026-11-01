import SwiftUI
import Textual
#if canImport(UIKit)
  import UIKit
#endif

struct AttachmentLoaderDemo: View {
  var body: some View {
    Form {
      Section {
        StructuredText(
          markdown: """
            These images are using an `URLAttachmentLoader` instance
            relative to `https://picsum.photos/seed/textual`:

            ![](400/250)
            ![](300/125)
            """,
          baseURL: URL(string: "https://picsum.photos/seed/textual/")
        )
        .textual.imageAttachmentLoader(
          .image(relativeTo: URL(string: "https://picsum.photos/seed/textual"))
        )
        .textual.textSelection(.enabled)
        #if canImport(UIKit)
          .textual.urlContextMenu { url in
            UIMenu(children: [UIAction(title: String(localized: "Copy URL")) { _ in UIPasteboard.general.url = url }])
          }
        #endif
      }
      Section {
        StructuredText(
          markdown: """
            This image is loaded from the asset catalog:

            ![](sad_dog)

            The same image is used as the `sad_dog` emoji :sad_dog:.
            """,
          syntaxExtensions: [
            .emoji([.init(shortcode: "sad_dog", url: URL(string: "sad_dog")!)])
          ]
        )
        .textual.imageAttachmentLoader(.image(named: \.lastPathComponent))
        .textual.emojiAttachmentLoader(.emoji(named: \.lastPathComponent))
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  AttachmentLoaderDemo()
}
