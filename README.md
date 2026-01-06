# Textual
[![CI](https://github.com/gonzalezreal/textual/workflows/CI/badge.svg)](https://github.com/gonzalezreal/textual/actions?query=workflow%3ACI)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fgonzalezreal%2Ftextual%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/gonzalezreal/textual)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fgonzalezreal%2Ftextual%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/gonzalezreal/textual)

Render and customize rich attributed text in SwiftUI.

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Demos](#demos)
- [Documentation](#documentation)
- [Installation](#installation)
- [License](#license)

## Overview

**Textual** is the spiritual successor to [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui), reimagined
from the ground up to address the lessons learned from community feedback. While MarkdownUI focuses on Markdown
rendering, Textual is designed as a SwiftUI text rendering engine that happens to support Markdown. This shift in
perspective influenced every design decision.

Textual preserves SwiftUI's `Text` rendering pipeline so you can get performance, composability, and automatic
platform adaptations. The rendering flow transforms markup into attributed content, resolves attachments asynchronously,
applies styling through environment values, and uses SwiftUI's layout system to position everything.

### Key features

- **Specialized views** with `InlineText` for inline-formatted text and `StructuredText` for block-based documents
- **Native text selection** with proper copy-paste support
- **Markdown support** via Foundation's `AttributedString` built-in parser
- **Custom markup parser support** through the `MarkupParser` protocol
- **Inline attachments** that flow with the text, such as images and custom emoji
- **Animated image support** (GIF, APNG, WebP)
- **Syntax highlighting** with customizable themes
- **Comprehensive styling** for headings, code blocks, tables, links, lists, and more
- **Font-relative** layout measurements that scale with text size and accessibility settings

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./Examples/TextualDemo/DemoDark.gif">
  <img alt="Demo" src="./Examples/TextualDemo/DemoLight.gif" width="322" height="700">
</picture>

## Getting started

For inline content with formatting, images, and links, use `InlineText`:

```swift
InlineText(
  markdown: """
    This is a *lighthearted* but **perfectly serious** paragraph where `inline code` lives \
    happily alongside ~~a terrible idea~~ a better one, a [useful link](https://example.com), \
    and a bit of _extra emphasis_ just for style. To keep things interesting without overdoing \
    it, here’s a completely random image that adapts to the container width:

    ![Random image](https://picsum.photos/seed/textual/400/250)
    """
)
```

This creates a view that renders formatted text and flows naturally within its container. `InlineText` is a drop-in
replacement for SwiftUI's `Text` with attachment support and comprehensive styling.

You can customize `InlineText` with standard SwiftUI modifiers (like `.font()` and `.foregroundStyle()`) or use
Textual's inline styling system:

```swift
InlineText(
  markdown: "Use `git status` to check _uncommitted changes_"
)
.font(.custom("Avenir Next", size: 18))
.textual.inlineStyle(
  InlineStyle()
    .code(
      .monospaced,
      .fontScale(0.85),
      .backgroundColor(.purple),
      .foregroundColor(.white)
    )
    .emphasis(.italic, .underlineStyle(.single))
)
```

For structured content with headings, paragraphs, lists, code blocks, and tables, use `StructuredText`:

```swift
StructuredText(
  markdown: """
    ## The Problem

    > After merging PR #347, users reported that tapping "Back" from the detail view would sometimes
    > navigate to a completely random screen. One user ended up in Settings while trying to return to
    > their inbox. Another saw the onboarding flow. Creative, but not ideal.

    Here's what we knew going in:

    - The issue only appeared **after** the state restoration changes
    - It happened _inconsistently_—maybe 1 in 5 back navigations
    - The stack trace was... let's call it "unhelpful"
    """
)
```

This renders a heading, a blockquote, a paragraph, and a bulleted list with appropriate spacing and styling. Each
block can be customized independently.

### The `MarkupParser` protocol

Textual ships with Markdown support built on top of Foundation's `AttributedString` markdown parser, but you can
plug in any format that can produce strings with [`PresentationIntent`](https://developer.apple.com/documentation/foundation/presentationintent)
attributes by conforming your parser to the `MarkupParser` protocol.

The built-in Markdown parser supports preprocessing patterns, like custom emoji. You can define emoji with shortcodes
that will be substituted during preprocessing:

```swift
let emoji: Set<Emoji> = [
  Emoji(
    shortcode: "rocket",
    url: URL(string: "https://example.com/rocket.png")!
  ),
  Emoji(
    shortcode: "sparkles",
    url: URL(string: "https://example.com/sparkles.gif")!
  ),
]

InlineText(
  markdown: "Shipped the new feature :rocket: and it's working :sparkles:",
  patternOptions: .init(emoji: emoji)
)
```

The preprocessing system provides the groundwork for future enhancements like math expression rendering.

### Text Selection

You can control whether users can select text within `InlineText` or `StructuredText` views with the
`textual.textSelection(_:)` modifier:

```swift
StructuredText(
  markdown: """
    ## The Problem
    ...
    """
)
.textual.textSelection(.enabled)
```

Scrollable regions like code blocks handle their own selection contexts. When you select text in a scrollable area,
any document-level selection clears automatically, and vice versa.

### Styling

Textual provides a flexible styling system that lets you customize every aspect of structured text rendering. At the
highest level, you can apply a complete style preset with a single modifier. For finer control, you can override
individual block types or create fully custom styles.

#### Built-in Styles

Textual includes two complete style presets: `.default` and `.gitHub`. Apply them using the
`textual.structuredTextStyle(_:)` modifier:

```swift
StructuredText(
  markdown: """
    ## The Problem
    ...
    """
)
.textual.structuredTextStyle(.gitHub)
```

This single modifier configures the entire rendering stack: inline styles (code, emphasis, strong, links), block styles
(headings, paragraphs, blockquotes, code blocks, tables), and list markers.

#### Customizing Individual Elements

You can override specific aspects of a style without rebuilding everything. Each block type has its own modifier:

```swift
StructuredText(markdown: content)
  .textual.structuredTextStyle(.gitHub)
  .textual.headingStyle(
    CustomHeadingStyle()
  )
  .textual.codeBlockStyle(
    CustomCodeBlockStyle()
  )
```

Here's a practical example, a custom heading style that adds a subtle underline to H1:

```swift
struct CustomHeadingStyle: StructuredText.HeadingStyle {
  private static let fontScales: [CGFloat] = [2, 1.5, 1.25, 1, 0.875, 0.85]
  
  func makeBody(configuration: Configuration) -> some View {
    let headingLevel = min(configuration.headingLevel, 6)
    let fontScale = Self.fontScales[headingLevel - 1]
    
    VStack(alignment: .leading, spacing: 0) {
      configuration.label
        .textual.fontScale(fontScale)
        .fontWeight(.semibold)

      if headingLevel == 1 {
        Divider()
          .textual.padding(.top, .fontScaled(0.25))
      }
    }
    .textual.blockSpacing(.fontScaled(top: 1.5, bottom: 0.5))
  }
}
```

The configuration provides the rendered label and context like heading level and indentation, which you can use to
build custom layouts and apply additional styling.

#### Font-Relative Measurements

Notice the `.fontScaled()` values in the example above. Textual's font-relative measurement system ensures your layouts
scale harmoniously with text size:

```swift
.textual.padding(.fontScaled(1.0))
.textual.blockSpacing(.fontScaled(top: 0.8, bottom: 1.2))
```

These measurements adapt automatically to the current font size, dynamic type settings, and accessibility preferences.
A padding of `.fontScaled(0.5)` creates padding that is half of the current font size. As users adjust text size, your
spacing scales proportionally.

You may have noticed the `.textual` prefix on modifiers throughout these examples. Textual organizes its view modifiers
under this namespace, making them easy to discover through autocomplete while avoiding potential naming conflicts with
SwiftUI or other libraries. When you type `.textual`, you see only Textual-specific capabilities.

Many modifiers in the `.textual` namespace accept font-relative measurements through `.fontScaled()` values. Beyond
padding and spacing, you can use these measurements for frame sizes, insets, and any numeric value where scaling with
text size makes sense.

#### Complete Custom Styles

For full control, implement the `StructuredText.Style` protocol. This lets you define every aspect of rendering in one
cohesive theme:

```swift
struct CompactStyle: StructuredText.Style {
  var inlineStyle: InlineStyle {
    InlineStyle()
      .code(.monospaced, .fontScale(0.9))
      .strong(.fontWeight(.semibold))
  }

  var headingStyle: some StructuredText.HeadingStyle {
    CompactHeadingStyle()
  }

  var paragraphStyle: some StructuredText.ParagraphStyle {
    CompactParagraphStyle()
  }

  // ... other block styles

  var unorderedListMarker: StructuredText.UnorderedListMarker {
    .hierarchical(.disc, .circle, .square)
  }

  var orderedListMarker: StructuredText.OrderedListMarker {
    .decimal
  }
}

// Then apply it:
StructuredText(markdown: content)
  .textual.structuredTextStyle(CompactStyle())
```

The protocol requires implementations for all block types, list markers, and inline styles. This ensures visual
consistency across your entire document.

## Demos

This repository includes a demo app that showcases all of Textual's features, from inline formatting and custom emoji
to advanced styling and syntax highlighting. Each feature is demonstrated in focused, isolated examples that are easy
to explore and reference.

The demo lives in [`Examples/TextualDemo`](./Examples/TextualDemo) and is included in `Textual.xcworkspace` at the
repository root. Open the workspace to browse the library source and run the demo side-by-side.

## Documentation

The latest documentation for Textual is available [here](https://swiftpackageindex.com/gonzalezreal/textual/main/documentation/textual).

## Installation

You can add Textual to an Xcode project by adding it to your project as a package.

> https://github.com/gonzalezreal/textual

If you want to use Textual in a [SwiftPM](https://swift.org/package-manager/) project, it's as
simple as adding it to your `Package.swift`:

``` swift
dependencies: [
  .package(url: "https://github.com/gonzalezreal/textual", from: "0.1.0")
]
```

And then adding the product to any target that needs access to the library:

```swift
.product(name: "Textual", package: "textual"),
```

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.
