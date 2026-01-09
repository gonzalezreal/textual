import SwiftUI

@usableFromInline
struct EmojiResourceAttachment: Attachment {
  @usableFromInline
  var description: String {
    ":\(text):"
  }

  @usableFromInline
  var selectionStyle: AttachmentSelectionStyle {
    .text
  }

  private let name: String
  private let bundle: Bundle?
  private let text: String
  private let image: SwiftUI.Image

  init(
    name: String,
    bundle: Bundle?,
    text: String,
    environment: ColorEnvironmentValues
  ) {
    self.name = name
    self.bundle = bundle
    self.text = text

    let platformImage =
      PlatformImage.resolve(
        name,
        bundle: bundle,
        environment: environment
      ) ?? .init()

    self.image = .init(platformImage)
  }

  @usableFromInline
  var body: some View {
    image
      .resizable()
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
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.name == rhs.name && lhs.bundle == rhs.bundle && lhs.text == rhs.text
  }

  @usableFromInline
  func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(bundle)
    hasher.combine(text)
  }
}
