import SwiftUI
import Textual

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
            """
        )
        .textual.imageAttachmentLoader(
          .image(relativeTo: URL(string: "https://picsum.photos/seed/textual"))
        )
      }
      Section {
        StructuredText(
          markdown: """
            This image is loaded from the asset catalog:

            ![](sad_dog)

            The same image is used as the `sad_dog` emoji :sad_dog:.
            """,
          patternOptions: .init(
            emoji: [.init(shortcode: "sad_dog", url: URL(string: "sad_dog")!)]
          )
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
