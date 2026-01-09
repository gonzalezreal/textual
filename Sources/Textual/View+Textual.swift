import SwiftUI

extension View {
  /// Provides access to Textual-specific modifiers.
  ///
  /// Use this property to access styling and configuration options for ``InlineText`` and
  /// ``StructuredText``. For example:
  ///
  /// ```swift
  /// StructuredText(markdown: "Hello, **world**!")
  ///   .textual.inlineStyle(.custom)
  ///   .textual.textSelection(.enabled)
  /// ```
  @inlinable public var textual: TextualNamespace<Self> { .init(self) }
}

extension TextualNamespace where Base: View {
  /// Sets the spacing above and below the current block.
  @MainActor public func blockSpacing(_ blockSpacing: StructuredText.BlockSpacing) -> some View {
    base.preference(key: StructuredText.BlockSpacingKey.self, value: blockSpacing)
  }

  /// Sets the spacing above and below the current block using a font-relative value.
  @MainActor public func blockSpacing(
    _ blockSpacing: FontScaled<StructuredText.BlockSpacing>
  ) -> some View {
    WithFontScaledValue(blockSpacing) { blockSpacing in
      base.preference(key: StructuredText.BlockSpacingKey.self, value: blockSpacing)
    }
  }

  /// Sets line spacing using a font-relative value.
  @MainActor public func lineSpacing(_ lineSpacing: FontScaled<CGFloat>) -> some View {
    WithFontScaledValue(lineSpacing) {
      base.lineSpacing($0)
    }
  }

  /// Adds padding using font-relative insets.
  @MainActor public func padding(_ insets: FontScaled<EdgeInsets>) -> some View {
    WithFontScaledValue(insets) {
      base.padding($0)
    }
  }

  /// Adds padding using a font-relative length.
  @MainActor public func padding(_ length: FontScaled<CGFloat>) -> some View {
    WithFontScaledValue(length) {
      base.padding($0)
    }
  }

  /// Adds padding on the specified edges using a font-relative length.
  @MainActor public func padding(_ edges: Edge.Set, _ length: FontScaled<CGFloat>) -> some View {
    WithFontScaledValue(length) {
      base.padding(edges, $0)
    }
  }

  /// Sets the view’s frame using font-relative dimensions.
  @MainActor public func frame(
    width: FontScaled<CGFloat>? = nil,
    height: FontScaled<CGFloat>? = nil,
    alignment: Alignment = .center
  ) -> some View {
    WithFontScaledValue(
      FontScaled(
        ProposedViewSize(
          width: width?.value,
          height: height?.value
        )
      )
    ) { size in
      base.frame(width: size.width, height: size.height, alignment: alignment)
    }
  }

  /// Sets the view’s minimum width using a font-relative value.
  @MainActor public func frame(
    minWidth: FontScaled<CGFloat>,
    alignment: Alignment = .center
  ) -> some View {
    WithFontScaledValue(minWidth) {
      base.frame(minWidth: $0, alignment: alignment)
    }
  }

  /// Sets the spacing used between list items in ``StructuredText``.
  public func listItemSpacing(
    _ listItemSpacing: FontScaled<StructuredText.BlockSpacing>
  ) -> some View {
    base.environment(\.listItemSpacing, listItemSpacing)
  }

  /// Sets the custom emoji properties.
  public func emojiProperties(_ emojiProperties: EmojiProperties) -> some View {
    base.environment(\.emojiProperties, emojiProperties)
  }
  
  public func mathProperties(_ mathProperties: MathProperties) -> some View {
    base.environment(\.mathProperties, mathProperties)
  }

  /// Scales the font used within the view by a constant factor.
  @MainActor public func fontScale(_ scale: CGFloat) -> some View {
    base.modifier(FontScaleModifier(scale))
  }

  /// Sets the attachment loader used to resolve image attachments.
  public func imageAttachmentLoader(_ loader: some AttachmentLoader) -> some View {
    base.environment(\.imageAttachmentLoader, loader)
  }

  /// Sets the attachment loader used to resolve custom emoji attachments.
  public func emojiAttachmentLoader(_ loader: some AttachmentLoader) -> some View {
    base.environment(\.emojiAttachmentLoader, loader)
  }

  /// Enables or disables text selection for ``InlineText`` and ``StructuredText``.
  @available(tvOS, unavailable)
  @available(watchOS, unavailable)
  @inlinable
  public func textSelection(_ selectability: some TextSelectability) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      base.environment(\.textSelection, type(of: selectability))
    #else
      base
    #endif
  }

  /// Sets the spacing used between table cells in ``StructuredText``.
  public func tableCellSpacing(
    horizontal: CGFloat? = nil,
    vertical: CGFloat? = nil
  ) -> some View {
    base.preference(
      key: StructuredText.TableCell.SpacingKey.self,
      value: .init(horizontal: horizontal, vertical: vertical)
    )
  }

  /// Controls how content that overflows horizontally behaves in ``Overflow``.
  ///
  /// Use ``OverflowMode/wrap`` to wrap content to the available width, or
  /// ``OverflowMode/scroll`` to allow horizontal scrolling.
  @inlinable
  public func overflowMode(_ overflowMode: OverflowMode) -> some View {
    base.environment(\.overflowMode, overflowMode)
  }

  /// Sets the inline style used by ``InlineText`` and ``StructuredText``.
  @inlinable
  public func inlineStyle(_ style: InlineStyle) -> some View {
    base.environment(\.inlineStyle, style)
  }

  /// Sets the paragraph style used by ``StructuredText``.
  @inlinable
  public func paragraphStyle(_ paragraphStyle: some StructuredText.ParagraphStyle) -> some View {
    base.environment(\.paragraphStyle, paragraphStyle)
  }

  /// Sets the heading style used by ``StructuredText``.
  @inlinable
  public func headingStyle(_ headingStyle: some StructuredText.HeadingStyle) -> some View {
    base.environment(\.headingStyle, headingStyle)
  }

  /// Sets the block quote style used by ``StructuredText``.
  @inlinable
  public func blockQuoteStyle(_ blockQuoteStyle: some StructuredText.BlockQuoteStyle) -> some View {
    base.environment(\.blockQuoteStyle, blockQuoteStyle)
  }

  /// Sets the list item style used by ``StructuredText``.
  @inlinable
  public func listItemStyle(
    _ listItemStyle: some StructuredText.ListItemStyle
  ) -> some View {
    base.environment(\.listItemStyle, listItemStyle)
  }

  /// Sets the ordered list marker used by ``StructuredText``.
  @inlinable
  public func orderedListMarker(
    _ orderedListMarker: some StructuredText.OrderedListMarker
  ) -> some View {
    base.environment(\.orderedListMarker, orderedListMarker)
  }

  /// Sets the unordered list marker used by ``StructuredText``.
  @inlinable
  public func unorderedListMarker(
    _ unorderedListMarker: some StructuredText.UnorderedListMarker
  ) -> some View {
    base.environment(\.unorderedListMarker, unorderedListMarker)
  }

  /// Sets the thematic break style used by ``StructuredText``.
  @inlinable
  public func thematicBreakStyle(
    _ thematicBreakStyle: some StructuredText.ThematicBreakStyle
  ) -> some View {
    base.environment(\.thematicBreakStyle, thematicBreakStyle)
  }

  /// Sets the syntax highlighting theme used by code blocks in ``StructuredText``.
  @inlinable
  public func highlighterTheme(_ highlighterTheme: StructuredText.HighlighterTheme) -> some View {
    base.environment(\.highlighterTheme, highlighterTheme)
  }

  /// Sets the code block style used by ``StructuredText``.
  @inlinable
  public func codeBlockStyle(
    _ codeBlockStyle: some StructuredText.CodeBlockStyle
  ) -> some View {
    base.environment(\.codeBlockStyle, codeBlockStyle)
  }

  /// Sets the table cell style used by ``StructuredText``.
  @inlinable
  public func tableCellStyle(
    _ tableCellStyle: some StructuredText.TableCellStyle
  ) -> some View {
    base.environment(\.tableCellStyle, tableCellStyle)
  }

  /// Sets the table style used by ``StructuredText``.
  @inlinable
  public func tableStyle(
    _ tableStyle: some StructuredText.TableStyle
  ) -> some View {
    base.environment(\.tableStyle, tableStyle)
  }

  /// Sets all the styles used by ``StructuredText``.
  ///
  /// Use this modifier when you want to apply a consistent look to structured text in one place.
  /// It sets the inline style, block styles, list markers, and code highlighting theme from a
  /// single ``StructuredText/Style`` value.
  @inlinable
  public func structuredTextStyle(_ style: some StructuredText.Style) -> some View {
    base
      .environment(\.inlineStyle, style.inlineStyle)
      .environment(\.headingStyle, style.headingStyle)
      .environment(\.paragraphStyle, style.paragraphStyle)
      .environment(\.blockQuoteStyle, style.blockQuoteStyle)
      .environment(\.codeBlockStyle, style.codeBlockStyle)
      .environment(\.listItemStyle, style.listItemStyle)
      .environment(\.unorderedListMarker, style.unorderedListMarker)
      .environment(\.orderedListMarker, style.orderedListMarker)
      .environment(\.tableStyle, style.tableStyle)
      .environment(\.tableCellStyle, style.tableCellStyle)
      .environment(\.thematicBreakStyle, style.thematicBreakStyle)
  }
}
