import SwiftUI

@usableFromInline
struct EmojiAttachment: Attachment {
  @usableFromInline
  var description: String {
    ":\(text):"
  }

  @usableFromInline
  var selectionStyle: AttachmentSelectionStyle {
    .text
  }

  private let image: Image
  private let text: String

  init(image: Image, text: String) {
    self.image = image
    self.text = text
  }

  @usableFromInline
  var body: some View {
    ImageView(image)
      .aspectRatio(contentMode: .fit)
  }

  @usableFromInline
  func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat {
    environment.emojiProperties.baselineOffset.resolve(in: environment)
  }

  @usableFromInline
  func sizeThatFits(_: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
    environment.emojiProperties.size.resolve(in: environment)
  }

  @usableFromInline
  func pngData() -> Data? {
    image.cgImage.pngData()
  }
}
