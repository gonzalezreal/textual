import Foundation

extension Formatter {
  func html() -> String {
    blockNodes.renderHTML()
  }
}

// MARK: - Inline rendering

extension Formatter.InlineNode {
  fileprivate func renderHTML() -> String {
    switch self {
    case .text(let text):
      return text.htmlEscaped()
    case .code(let code):
      return "<code>\(code.htmlEscaped())</code>"
    case .strong(let children):
      return "<strong>\(children.renderHTML())</strong>"
    case .emphasized(let children):
      return "<em>\(children.renderHTML())</em>"
    case .strikethrough(let children):
      return "<del>\(children.renderHTML())</del>"
    case .link(let url, let children):
      let href = url.absoluteString.htmlAttributeEscaped()
      return #"<a href="\#(href)">\#(children.renderHTML())</a>"#
    case .lineBreak:
      return "<br />"
    case .attachment(let attachment):
      guard let imageData = attachment.pngData() else {
        return attachment.description.htmlEscaped()
      }
      let base64 = imageData.base64EncodedString()
      return #"<img src="data:image/png;base64,\#(base64)" />"#
    }
  }
}

extension Array where Element == Formatter.InlineNode {
  fileprivate func renderHTML() -> String {
    self.map {
      $0.renderHTML()
    }.joined()
  }
}

// MARK: - Block rendering

extension Formatter.BlockNode {
  fileprivate func renderHTML() -> String {
    switch self {
    case .paragraph(let children):
      return "<p>\(children.renderHTML())</p>"
    case .header(let level, let children):
      let l = max(1, min(6, level))
      return "<h\(l)>\(children.renderHTML())</h\(l)>"
    case .orderedList(let children):
      let start = children.map(\.ordinal).min() ?? 1
      let startAttribute = start > 1 ? #" start="\#(start)""# : ""
      return "<ol\(startAttribute)>\n\(children.renderHTML())\n</ol>"
    case .unorderedList(let children):
      return "<ul>\n\(children.renderHTML())\n</ul>"
    case .codeBlock(let languageHint, let code):
      let classAttribute =
        languageHint.flatMap {
          $0.isEmpty ? nil : $0
        }.map {
          #" class="language-\#($0.htmlAttributeEscaped())""#
        } ?? ""
      return "<pre><code\(classAttribute)>\(code.htmlCodeEscaped())</code></pre>"
    case .blockQuote(let children):
      return "<blockquote>\n\(children.renderHTML())\n</blockquote>"
    case .table(let columns, let children):
      guard let headerHTML = children.first?.renderHeaderHTML(columns: columns) else {
        return "<table></table>"
      }
      let bodyHTML = Array(children.dropFirst()).renderHTML(columns: columns)

      if bodyHTML.isEmpty {
        return "<table>\n<thead>\n\(headerHTML)\n</thead>\n</table>"
      } else {
        return "<table>\n<thead>\n\(headerHTML)\n</thead>\n\(bodyHTML)\n</table>"
      }
    case .thematicBreak:
      return "<hr />"
    }
  }
}

extension Array where Element == Formatter.BlockNode {
  fileprivate func renderHTML() -> String {
    self.map {
      $0.renderHTML()
    }.joined(separator: "\n")
  }
}

// MARK: - Table rendering

extension Formatter.TableRow {
  fileprivate func renderHeaderHTML(columns: [PresentationIntent.TableColumn]) -> String {
    renderHTML("th", columns: columns)
  }

  fileprivate func renderDataHTML(columns: [PresentationIntent.TableColumn]) -> String {
    renderHTML("td", columns: columns)
  }

  private func renderHTML(
    _ element: String,
    columns: [PresentationIntent.TableColumn]
  ) -> String {
    let alignments = columns.map(\.alignment)
    let cells = zip(alignments, self.cells).map { alignment, inlines in
      #"<\#(element) align="\#(alignment)">\#(inlines.renderHTML())</\#(element)>"#
    }
    return "<tr>\n\(cells.joined(separator: "\n"))\n</tr>"
  }
}

extension Array where Element == Formatter.TableRow {
  fileprivate func renderHTML(columns: [PresentationIntent.TableColumn]) -> String {
    self.map {
      $0.renderDataHTML(columns: columns)
    }.joined(separator: "\n")
  }
}

// MARK: - List rendering

extension Formatter.ListItem {
  fileprivate func renderHTML() -> String {
    // NB: Tight vs. loose list detection. When Markdown has blank lines between list items,
    //     the parser creates multiple paragraph blocks. Single paragraph = tight (no <p> tags),
    //     multiple paragraphs = loose (wrap content in <p> tags).
    let paragraphCount = blocks.filter {
      if case .paragraph = $0 { return true }
      return false
    }.count

    // Tight list - single paragraph
    if paragraphCount == 1,
      blocks.count == 1,
      case .paragraph(let children) = blocks[0]
    {
      return "<li>\(children.renderHTML())</li>"
    }

    // Tight list with single paragraph + other blocks (nested lists, etc.)
    if paragraphCount == 1,
      let firstParagraphIndex = blocks.firstIndex(where: {
        if case .paragraph = $0 { return true }
        return false
      }),
      case .paragraph(let children) = blocks[firstParagraphIndex]
    {
      let otherBlocks = blocks.enumerated().filter { $0.offset != firstParagraphIndex }.map {
        $0.element
      }
      let otherHTML = otherBlocks.renderHTML()
      return "<li>\(children.renderHTML())\(otherHTML)</li>"
    }

    // Loose list - multiple paragraphs mean blank lines existed
    return "<li>\(blocks.renderHTML())</li>"
  }
}

extension Array where Element == Formatter.ListItem {
  fileprivate func renderHTML() -> String {
    self.map {
      $0.renderHTML()
    }.joined(separator: "\n")
  }
}

// MARK: - String escaping

extension String {
  // For text content. Escapes &, <, >, and non-ASCII characters.
  fileprivate func htmlEscaped() -> String {
    var result = ""
    result.reserveCapacity(utf8.count)

    for scalar in self.unicodeScalars {
      switch scalar.value {
      case 0x26:  // &
        result.append("&amp;")
      case 0x3C:  // <
        result.append("&lt;")
      case 0x3E:  // >
        result.append("&gt;")
      case 0x20...0x7E:
        result.append(Character(scalar))
      default:
        result.append("&#\(scalar.value);")
      }
    }

    return result
  }

  // For code blocks. Only escapes &, <, > to preserve whitespace.
  fileprivate func htmlCodeEscaped() -> String {
    var result = ""
    result.reserveCapacity(utf8.count)

    for scalar in self.unicodeScalars {
      switch scalar.value {
      case 0x26:  // &
        result.append("&amp;")
      case 0x3C:  // <
        result.append("&lt;")
      case 0x3E:  // >
        result.append("&gt;")
      default:
        result.append(Character(scalar))
      }
    }

    return result
  }

  // For attribute values. Escapes &, <, >, ", and non-ASCII characters.
  fileprivate func htmlAttributeEscaped() -> String {
    var result = ""
    result.reserveCapacity(utf8.count)

    for scalar in self.unicodeScalars {
      switch scalar.value {
      case 0x26:  // &
        result.append("&amp;")
      case 0x3C:  // <
        result.append("&lt;")
      case 0x3E:  // >
        result.append("&gt;")
      case 0x22:  // "
        result.append("&quot;")
      case 0x20...0x7E:
        result.append(Character(scalar))
      default:
        result.append("&#\(scalar.value);")
      }
    }

    return result
  }
}
