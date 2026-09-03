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
  /// Memoizes the `TextBuilder` for the current content so `body` can derive it directly.
  @MainActor
  final class BuilderCache {
    private var content: Content?
    private var environment: TextEnvironmentValues?
    private var builder: TextBuilder?

    func builder(for content: Content, environment: TextEnvironmentValues) -> TextBuilder {
      if let builder, content == self.content, environment == self.environment {
        return builder
      }
      let builder = TextBuilder(content, environment: environment)
      self.content = content
      self.environment = environment
      self.builder = builder
      return builder
    }
  }

  @Environment(\.textEnvironment) private var textEnvironment
  @State private var builderCache = BuilderCache()

  private let content: Content

  init(_ content: Content) {
    self.content = content
  }

  var body: some View {
    builderCache.builder(for: content, environment: textEnvironment).text
      .customAttribute(TextFragmentAttribute())
      .onGeometryChange(for: CGSize?.self, of: \.textContainerSize) { size in
        guard let size else { return }
        builderCache.builder(for: content, environment: textEnvironment)
          .sizeChanged(size, environment: textEnvironment)
      }
      .modifier(TextSelectionBackground())
      .modifier(AttachmentOverlay(attachments: content.attachments()))
      .modifier(TextLinkInteraction())
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
