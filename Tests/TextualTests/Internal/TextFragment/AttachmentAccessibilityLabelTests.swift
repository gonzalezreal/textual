import SwiftUI
import Testing

@testable import Textual

@MainActor
struct AttachmentAccessibilityLabelTests {
  @Test func readsTheLabelInPlaceOfTheAttachment() {
    let builder = TextFragment<AttributedString>.TextBuilder(
      Self.text("Ask ", Mention(label: "Editor"), " to make a clip."),
      environment: .init()
    )

    #expect(builder.accessibilityLabel == "Ask Editor to make a clip.")
  }

  @Test func leavesTextWithoutLabelsAlone() {
    let unlabeled = TextFragment<AttributedString>.TextBuilder(
      Self.text("Ask ", Mention(label: nil), " to make a clip."),
      environment: .init()
    )
    let plain = TextFragment<AttributedString>.TextBuilder(
      AttributedString("Ask to make a clip."),
      environment: .init()
    )

    #expect(unlabeled.accessibilityLabel == nil)
    #expect(plain.accessibilityLabel == nil)
  }

  private static func text(_ prefix: String, _ mention: Mention, _ suffix: String)
    -> AttributedString
  {
    var attachment = AttributedString("\u{FFFC}")
    attachment.textual.attachment = AnyAttachment(mention)
    return AttributedString(prefix) + attachment + AttributedString(suffix)
  }
}

private struct Mention: Textual.Attachment {
  let label: String?

  var description: String {
    label ?? ""
  }

  var accessibilityLabel: String? {
    label
  }

  var body: some View {
    Color.clear
  }

  func sizeThatFits(_: ProposedViewSize, in _: TextEnvironmentValues) -> CGSize {
    CGSize(width: 24, height: 24)
  }
}
