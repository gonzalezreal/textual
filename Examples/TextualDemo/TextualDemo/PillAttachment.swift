import SwiftUI
import Textual

/// A custom attachment that renders as a citation pill matching Figma design
/// Light peachy background (#f4e7dd), paperclip emoji, rounded corners (8px)
struct PillAttachment: Attachment {
  let text: String
  let onTap: (@Sendable () -> Void)?

  nonisolated var description: String {
    text
  }

  nonisolated var selectionStyle: AttachmentSelectionStyle {
    .text  // Treat as inline text, not dimmed when selected
  }

  @MainActor
  var body: some View {
    Button(action: { onTap?() }) {
      HStack(spacing: 4) {
        // Paperclip emoji
        Text("📎")
          .font(.system(size: 12))

        // Text label
        Text(text)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Color(red: 0x21/255.0, green: 0x12/255.0, blue: 0x17/255.0))
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color(red: 0xf4/255.0, green: 0xe7/255.0, blue: 0xdd/255.0))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .fixedSize()  // Prevent stretching in Canvas mode
    }
    .buttonStyle(.plain)
  }

  nonisolated func sizeThatFits(_ proposal: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
    // Accurate sizing using actual text measurement to prevent stretching in Canvas mode
    // Icon: 12pt emoji, gap: 4pt, text: measured, padding: 8pt each side
    return AttachmentSizing.measurePill(
      text: text,
      iconWidth: 12,         // Emoji width
      fontSize: 12,          // Text font size
      fontWeight: .medium,   // Text font weight
      horizontalPadding: 16, // 8pt left + 8pt right
      verticalPadding: 8,    // 4pt top + 4pt bottom
      spacing: 4             // Gap between emoji and text
    )
  }

  nonisolated func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat {
    // Align pill vertically with surrounding text baseline
    // Height is 20, adjust to sit nicely with text
    -3
  }

  // MARK: - Hashable

  nonisolated static func == (lhs: PillAttachment, rhs: PillAttachment) -> Bool {
    lhs.text == rhs.text
  }

  nonisolated func hash(into hasher: inout Hasher) {
    hasher.combine(text)
  }
}
