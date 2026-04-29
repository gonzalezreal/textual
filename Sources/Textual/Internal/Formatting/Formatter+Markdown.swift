import Foundation

extension Formatter {
  func markdown() -> String {
    blockNodes.renderMarkdown()
  }
}

// MARK: - Inline rendering

extension Formatter.InlineNode {
  fileprivate func renderMarkdown() -> String {
    switch self {
    case .text(let text):
      return text
    case .code(let code):
      return "`\(code)`"
    case .strong(let children):
      return "**\(children.renderMarkdown())**"
    case .emphasized(let children):
      return "*\(children.renderMarkdown())*"
    case .strikethrough(let children):
      return "~~\(children.renderMarkdown())~~"
    case .link(let url, let children):
      return "[\(children.renderMarkdown())](\(url.absoluteString))"
    case .lineBreak:
      return "  \n"
    case .attachment(let attachment):
      return attachment.description
    }
  }
}

extension Array where Element == Formatter.InlineNode {
  fileprivate func renderMarkdown() -> String {
    self.map { $0.renderMarkdown() }.joined()
  }
}

// MARK: - Block rendering

extension Formatter.BlockNode {
  fileprivate func renderMarkdown(indentationLevel: Int, tightSpacing: Bool) -> String {
    switch self {
    case .paragraph(let children):
      return children.renderMarkdown().indentedMarkdown(indentationLevel)
    case .header(let level, let children):
      let prefix = String(repeating: "#", count: level) + " "
      return (prefix + children.renderMarkdown()).indentedMarkdown(indentationLevel)
    case .orderedList(let children):
      return children.renderOrderedMarkdown(indentationLevel: indentationLevel)
    case .unorderedList(let children):
      return children.renderUnorderedMarkdown(indentationLevel: indentationLevel)
    case .codeBlock(let languageHint, let code):
      let fence = "```"
      let lang = languageHint ?? ""
      return "\(fence)\(lang)\n\(code)\n\(fence)".indentedMarkdown(indentationLevel)
    case .blockQuote(let children):
      let inner = children.renderMarkdown(indentationLevel: 0, tightSpacing: tightSpacing)
      return inner
        .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        .map { "> \($0)" }
        .joined(separator: "\n")
        .indentedMarkdown(indentationLevel)
    case .table(let columns, let children):
      return children.renderMarkdownTable(columns: columns, indentationLevel: indentationLevel)
    case .thematicBreak:
      return "---"
    }
  }
}

extension Array where Element == Formatter.BlockNode {
  fileprivate func renderMarkdown(indentationLevel: Int = 0, tightSpacing: Bool = false)
    -> String
  {
    self.map {
      $0.renderMarkdown(indentationLevel: indentationLevel, tightSpacing: tightSpacing)
    }.joined(separator: tightSpacing ? "\n" : "\n\n")
  }
}

// MARK: - Table rendering

extension Array where Element == Formatter.TableRow {
  fileprivate func renderMarkdownTable(
    columns: [PresentationIntent.TableColumn],
    indentationLevel: Int
  ) -> String {
    guard let header = first else { return "" }
    let headerLine = "| " + header.cells.map { $0.renderMarkdown() }.joined(separator: " | ") + " |"
    let separator = "| " + columns.map { col -> String in
      switch col.alignment {
      case .center: return ":---:"
      case .right:  return "---:"
      default:      return "---"
      }
    }.joined(separator: " | ") + " |"
    let bodyLines = dropFirst().map { row in
      "| " + row.cells.map { $0.renderMarkdown() }.joined(separator: " | ") + " |"
    }
    return ([headerLine, separator] + bodyLines).joined(separator: "\n")
      .indentedMarkdown(indentationLevel)
  }
}

// MARK: - List rendering

extension Formatter.ListItem {
  fileprivate func renderOrderedMarkdown(indentationLevel: Int) -> String {
    let content = blocks.renderMarkdown(indentationLevel: 0, tightSpacing: true)
    return content.prefixedMarkdown(
      with: "\(ordinal). ", indentationLevel: indentationLevel)
  }

  fileprivate func renderUnorderedMarkdown(indentationLevel: Int) -> String {
    let content = blocks.renderMarkdown(indentationLevel: 0, tightSpacing: true)
    return content.prefixedMarkdown(
      with: "- ", indentationLevel: indentationLevel)
  }
}

extension Array where Element == Formatter.ListItem {
  fileprivate func renderOrderedMarkdown(indentationLevel: Int) -> String {
    self.map { $0.renderOrderedMarkdown(indentationLevel: indentationLevel) }
      .joined(separator: "\n")
  }

  fileprivate func renderUnorderedMarkdown(indentationLevel: Int) -> String {
    self.map { $0.renderUnorderedMarkdown(indentationLevel: indentationLevel) }
      .joined(separator: "\n")
  }
}

// MARK: - String helpers

extension String {
  fileprivate func indentedMarkdown(_ level: Int) -> String {
    guard level > 0 else { return self }
    let indent = String(repeating: "  ", count: level)
    return self
      .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
      .map { indent + $0 }
      .joined(separator: "\n")
  }

  fileprivate func prefixedMarkdown(with prefix: String, indentationLevel: Int) -> String {
    let indent = String(repeating: "  ", count: indentationLevel)
    let firstLineEnd = self.firstIndex(where: \.isNewline) ?? self.endIndex
    var firstLine = self[..<firstLineEnd]
    let rest = self[firstLineEnd...]

    if indentationLevel > 0, firstLine.hasPrefix(indent) {
      firstLine = firstLine.dropFirst(indent.count)
    }

    return indent + prefix + firstLine + rest
  }
}
