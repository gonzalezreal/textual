import SwiftUI

/// A view that displays rich, structured text.
///
/// `StructuredText` renders block elements like paragraphs, headings, lists, block quotes, code
/// blocks, and tables from a markup string. The markup is parsed with a ``MarkupParser`` into an
/// `AttributedString` that Textual can lay out and display.
///
/// The simplest way to create a `StructuredText` view is to pass Markdown:
///
/// ```swift
/// let markdown = """
/// ## Getting Started
///
/// Before making changes, check a few things:
///
/// - Skim recent commits
/// - Run the tests
/// - Make your changes
///
/// Leave a note if something needs attention later.
/// """
///
/// var body: some View {
///   StructuredText(markdown: markdown)
/// }
/// ```
///
/// ### Customizing Text Appearance
///
/// `StructuredText` supports standard SwiftUI text modifiers like `.font()`, `.foregroundStyle()`,
/// and `.multilineTextAlignment()`. Note that `.lineLimit()` is explicitly disabled to prevent
/// per-block truncation, which would break the document layout.
///
/// ```swift
/// StructuredText(markdown: "## Hello\n\nThis is a paragraph.")
///   .font(.callout)
///   .foregroundStyle(.blue)
///   .multilineTextAlignment(.center)
/// ```
///
/// ### Styling Structured Text
///
/// You can apply a full style preset using the ``TextualNamespace/structuredTextStyle(_:)`` modifier.
///
/// ```swift
/// StructuredText(markdown: markdown)
///   .textual.structuredTextStyle(.gitHub)
/// ```
///
/// For more control, you can customize individual block and inline styles. Inline styles
/// apply to spans like emphasis and links. Block styles apply to structural elements:
///
/// - ``TextualNamespace/headingStyle(_:)``, ``TextualNamespace/paragraphStyle(_:)``,
///   ``TextualNamespace/blockQuoteStyle(_:)``, ``TextualNamespace/thematicBreakStyle(_:)``
/// - ``TextualNamespace/listItemStyle(_:)``, ``TextualNamespace/unorderedListMarker(_:)``,
///   ``TextualNamespace/orderedListMarker(_:)``
/// - ``TextualNamespace/codeBlockStyle(_:)``, ``TextualNamespace/highlighterTheme(_:)``
/// - ``TextualNamespace/tableStyle(_:)``, ``TextualNamespace/tableCellStyle(_:)``
///
/// Code blocks and tables may overflow horizontally. You can choose between scrolling and
/// wrapping with ``TextualNamespace/overflowMode(_:)``.
///
/// ```swift
/// StructuredText(markdown: markdown)
///   .textual.overflowMode(.wrap)
/// ```
///
/// ### Interaction
///
/// When the markup contains links, `StructuredText` uses SwiftUI’s `openURL` environment. Provide a
/// custom `OpenURLAction` to intercept them (for example, to route in-app or to scroll to anchors).
///
/// You can enable text selection with ``TextualNamespace/textSelection(_:)`` to let users select
/// text in a platform-appropriate way.
///
/// ```swift
/// StructuredText(markdown: markdown)
///   .environment(
///     \.openURL,
///     OpenURLAction { url in
///       print("Open \(url)")
///       return .handled
///     }
///   )
///   .textual.textSelection(.enabled)
/// ```
///
/// ### Images, links, and relative URLs
///
/// If your Markdown includes relative image URLs or links, provide a `baseURL`. To render images,
/// configure an attachment loader using the ``TextualNamespace/imageAttachmentLoader(_:)``
/// modifier.
///
/// ```swift
/// let baseURL = URL(string: "https://example.com/repo/")!
///
/// StructuredText(markdown: readme, baseURL: baseURL)
///   .textual.imageAttachmentLoader(.image(relativeTo: baseURL))
/// ```
///
/// When you need to parse something other than Markdown, use ``init(_:parser:)`` with a custom
/// ``MarkupParser`` implementation.
public struct StructuredText: View {
  @State private var attributedString = AttributedString()

  private let markup: String
  private let parser: any MarkupParser

  /// Creates a structured-text view by parsing `markup` with a custom parser.
  ///
  /// Use this initializer when you want to provide your own `MarkupParser` implementation.
  public init(_ markup: String, parser: any MarkupParser) {
    self.markup = markup
    self.parser = parser
  }

  public var body: some View {
    WithAttachments(attributedString) {
      BlockContent(content: $0)
        .modifier(TextSelectionInteraction())
        .modifier(TextSelectionCoordination())
    }
    .coordinateSpace(.textContainer)
    .onChange(of: markup, initial: true) {
      markupDidChange(markup)
    }
    // Disable line limit to avoid per-fragment truncation
    .lineLimit(nil)
  }

  private func markupDidChange(_ markup: String) {
    self.attributedString = (try? parser.attributedString(for: markup)) ?? .init()
  }
}

extension StructuredText {
  /// Creates a structured-text view from a Markdown string.
  ///
  /// This is a convenience initializer that uses Textual’s Markdown parser. To render other
  /// markup formats, use ``init(_:parser:)`` with a custom ``MarkupParser``.
  ///
  /// - Parameters:
  ///   - markdown: The Markdown source to render.
  ///   - baseURL: A base URL used to resolve relative links and image URLs.
  ///   - patternOptions: Options for pattern substitution after markdown parsing.
  ///
  /// Math expressions are supported when you enable them in `patternOptions`:
  ///
  /// ```swift
  /// StructuredText(
  ///   markdown: "The area is $A = \\pi r^2$.",
  ///   patternOptions: .init(mathExpressions: true)
  /// )
  /// ```
  public init(
    markdown: String,
    baseURL: URL? = nil,
    patternOptions: AttributedStringMarkdownParser.PatternOptions = .init()
  ) {
    self.init(
      markdown,
      parser: .markdown(
        baseURL: baseURL,
        patternOptions: patternOptions
      )
    )
  }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
#Preview(traits: .fixedLayout(width: 400, height: 600)) {
  @Previewable @State var width: CGFloat = 200

  VStack {
    GroupBox {
      HStack {
        Text("Width")
        Slider(value: $width, in: 100...320)
      }
    }
    Spacer()

    StructuredText(
      markdown: """
        Morty, do you know what _“wubba lubba dub dub”_ means?

        ![Hamster in Butt World](https://rickandmortyapi.com/api/character/avatar/153.jpeg)

        I mean, why would a [Pop-Tart](https://en.wikipedia.org/wiki/Pop-Tarts) \
        want to live inside a toaster, Rick? I mean, that would be like the \
        scariest place for them to live. You know what I mean?
        """
    )
    .frame(width: width)
    .border(Color.red)
    .environment(
      \.openURL,
      OpenURLAction { url in
        print("Opening \(url)")
        return .handled
      }
    )
    .padding()
    .textual.textSelection(.enabled)

    Spacer()
  }
}

#Preview("Custom Emoji") {
  let emoji: Set<Emoji> = [
    Emoji(shortcode: "dog", url: URL(string: "https://picsum.photos/id/237/32/32")!),
    Emoji(shortcode: "cat", url: URL(string: "https://picsum.photos/id/1025/32/32")!),
  ]

  ScrollView {
    StructuredText(
      markdown: """
        # Working with Custom Emoji

        You can substitute shortcodes with inline images. For example, :dog: and :cat: render \
        as small inline attachments that flow with the surrounding text.
        """,
      patternOptions: .init(emoji: emoji)
    )
    .padding()
  }
}
