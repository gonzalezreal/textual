import SwiftUI

extension StructuredText {
  /// A GitHub-like set of styles for structured text.
  ///
  /// Apply with ``TextualNamespace/structuredTextStyle(_:)``. Pass a custom
  /// ``StructuredText/CodeBlockStyle`` to replace the default GitHub code block
  /// chrome while keeping every other block style unchanged.
  public struct GitHubStyle<CodeBlock: StructuredText.CodeBlockStyle>: Style {
    public let inlineStyle: InlineStyle = .gitHub
    public let headingStyle: GitHubHeadingStyle = .gitHub
    public let paragraphStyle: GitHubParagraphStyle = .gitHub
    public let blockQuoteStyle: GitHubBlockQuoteStyle = .gitHub
    public let codeBlockStyle: CodeBlock
    public let listItemStyle: DefaultListItemStyle = .default
    public let unorderedListMarker: HierarchicalSymbolListMarker = .hierarchical(
      .disc, .circle, .square)
    public let orderedListMarker: DecimalListMarker = .decimal
    public let tableStyle: GitHubTableStyle = .gitHub
    public let tableCellStyle: GitHubTableCellStyle = .gitHub
    public let thematicBreakStyle: GitHubThematicBreakStyle = .gitHub

    public init(codeBlockStyle: CodeBlock) {
      self.codeBlockStyle = codeBlockStyle
    }
  }
}

extension StructuredText.GitHubStyle where CodeBlock == StructuredText.GitHubCodeBlockStyle {
  /// Creates the default GitHub style (stock code block chrome).
  public init() {
    self.init(codeBlockStyle: .gitHub)
  }
}

extension StructuredText.Style
where Self == StructuredText.GitHubStyle<StructuredText.GitHubCodeBlockStyle> {
  /// A GitHub-like structured text style.
  public static var gitHub: Self {
    .init()
  }
}
