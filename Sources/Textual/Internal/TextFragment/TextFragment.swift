import SwiftUI

// MARK: - Overview
//
// TextFragment renders attributed content as SwiftUI.Text with support for inline
// attachments, links, and selection. It uses a TextBuilder to construct and cache
// Text values, minimizing rebuilds during resize by keying on attachment sizes.
//
// Attachments are represented as placeholder images tagged with AttachmentAttribute. The
// actual attachment views are rendered in an overlay using the resolved Text.Layout
// geometry. Three modifiers are applied at the fragment level:
//
// - TextSelectionBackground renders selection highlights on macOS
// - AttachmentOverlay draws attachments at their run locations with selection-aware dimming
// - TextLinkInteraction handles tap gestures on links
//
// These overlays use backgroundPreferenceValue and overlayPreferenceValue to access
// Text.Layout and render in fragment-local coordinates. Fragment-level overlays enable
// coordinate space isolation and keep scrollable regions interactive.
//
// An ancestor view must define a named coordinate space (.textContainer) for the text
// container. TextFragment uses onGeometryChange to observe the container size and rebuild
// Text when attachment sizes need to change.
//
// TextFragment is used by InlineText and StructuredText (via BlockContent) to render
// attributed content with inline attachments, links, and selection.

struct TextFragment<Content: AttributedStringProtocol>: View {
  @Environment(\.textEnvironment) private var textEnvironment
  @State private var textBuilder: TextBuilder?

  private let content: Content

  init(_ content: Content) {
    self.content = content
  }

  var body: some View {
    let attachments = content.attachments()
    print("📋 TextFragment attachments: \(attachments.count)")
    for attachment in attachments {
      print("  - \(attachment.description)")
    }
    return text
      .customAttribute(TextFragmentAttribute())
      .onGeometryChange(for: CGSize?.self, of: \.textContainerSize) { size in
        guard let size, let textBuilder else { return }
        textBuilder.sizeChanged(size, environment: textEnvironment)
      }
      .onChange(of: content, initial: true) { _, newValue in
        self.textBuilder = TextBuilder(newValue, environment: textEnvironment)
      }
      .modifier(TextSelectionBackground())
      .modifier(AttachmentOverlay(attachments: attachments))
      .modifier(TextLinkInteraction())
  }

  private var text: Text {
    textBuilder?.text ?? Text(verbatim: "")
  }
}

struct TextFragmentAttribute: TextAttribute {
}

extension Text.Layout {
  var isTextFragment: Bool {
    first?.first?[TextFragmentAttribute.self] != nil
  }
}

extension CoordinateSpaceProtocol where Self == NamedCoordinateSpace {
  static var textContainer: NamedCoordinateSpace {
    .named("textContainer")
  }
}

extension GeometryProxy {
  fileprivate var textContainerSize: CGSize? {
    bounds(of: .textContainer)?.size
  }
}
