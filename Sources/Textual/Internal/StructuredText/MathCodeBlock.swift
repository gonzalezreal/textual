import SwiftUI

extension StructuredText {
  struct MathCodeBlock: View {
    @Environment(\.paragraphStyle) private var paragraphStyle
    @Environment(\.mathProperties) private var mathProperties

    private let content: AttributedString
    private let indentationLevel: Int

    init(_ content: AttributedSubstring) {
      let latex = String(content.characters[...])
        .trimmingCharacters(in: .whitespacesAndNewlines)
      let attachment = MathAttachment(latex: latex, style: .block)
      self.content = AttributedString(
        "\u{FFFC}",
        attributes: AttributeContainer().attachment(.init(attachment))
      )
      self.indentationLevel = content.presentationIntent?.indentationLevel ?? 0
    }

    var body: some View {
      let configuration = BlockStyleConfiguration(
        label: .init(label),
        indentationLevel: indentationLevel
      )
      let resolvedStyle = paragraphStyle.resolve(configuration: configuration)

      AnyView(resolvedStyle)
        .layoutValue(key: BlockAlignmentKey.self, value: mathProperties.textAlignment)
    }

    private var label: some View {
      WithInlineStyle(content) {
        TextFragment($0)
      }
    }
  }
}
