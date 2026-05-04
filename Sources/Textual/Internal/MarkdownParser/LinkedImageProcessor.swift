import Foundation

// Foundation's Markdown parser drops linked images like `[![](image.png)](link)`: empty-alt
// images disappear entirely, and non-empty alt text keeps only the outer link. This processor
// works around that by rewriting linked images into ordinary image Markdown before parsing, then
// restoring the parsed image run with the outer link attached.
struct LinkedImageProcessor {
  private let baseURL: URL?

  init(baseURL: URL?) {
    self.baseURL = baseURL
  }

  func preprocess(_ input: String) -> Output {
    var markdown = ""
    var links: [String: Link] = [:]
    var index = input.startIndex

    while index < input.endIndex {
      if let range = codeFenceRange(at: index, in: input) {
        markdown += input[range]
        index = range.upperBound
      } else if let range = codeSpanRange(at: index, in: input) {
        markdown += input[range]
        index = range.upperBound
      } else if let linkedImage = linkedImage(at: index, in: input, tokenIndex: links.count) {
        markdown += linkedImage.markdown
        links[linkedImage.token] = linkedImage.link
        index = linkedImage.range.upperBound
      } else {
        markdown.append(input[index])
        index = input.index(after: index)
      }
    }

    return Output(markdown: markdown, links: links)
  }

  func restore(_ attributedString: AttributedString, from output: Output) -> AttributedString {
    guard !output.links.isEmpty else {
      return attributedString
    }

    var restored = AttributedString()

    for run in attributedString.runs {
      let substring = attributedString[run.range]
      let text = String(substring.characters[...])

      guard let link = output.links[text], run.imageURL != nil else {
        restored.append(substring)
        continue
      }

      var replacement = AttributedString(
        link.altText.isEmpty ? "\u{FFFC}" : link.altText,
        attributes: run.attributes
      )
      replacement.link = destinationURL(from: link.destination)

      restored.append(replacement)
    }

    return restored
  }

  private func linkedImage(
    at index: String.Index,
    in input: String,
    tokenIndex: Int
  ) -> LinkedImage? {
    guard input[index...].hasPrefix("[![") else {
      return nil
    }

    var cursor = input.index(index, offsetBy: 3)

    guard let altText = bracketedContent(startingAt: cursor, closing: "]", in: input) else {
      return nil
    }

    cursor = altText.range.upperBound

    guard
      cursor < input.endIndex,
      input[cursor] == "(",
      let imageDestination = parenthesizedContent(startingAt: cursor, in: input)
    else {
      return nil
    }

    cursor = imageDestination.range.upperBound

    guard
      cursor < input.endIndex,
      input[cursor] == "]"
    else {
      return nil
    }

    cursor = input.index(after: cursor)

    guard
      cursor < input.endIndex,
      input[cursor] == "(",
      let linkDestination = parenthesizedContent(startingAt: cursor, in: input)
    else {
      return nil
    }

    let token = token(for: tokenIndex, in: input)
    return LinkedImage(
      range: index..<linkDestination.range.upperBound,
      markdown: "![\(token)](\(imageDestination.content))",
      token: token,
      link: Link(
        altText: altText.content,
        destination: linkDestination.content
      )
    )
  }

  private func bracketedContent(
    startingAt start: String.Index,
    closing: Character,
    in input: String
  ) -> Content? {
    var index = start

    while index < input.endIndex {
      if input[index] == "\\" {
        index = input.index(after: index)
        if index < input.endIndex {
          index = input.index(after: index)
        }
        continue
      }

      if input[index] == closing {
        return Content(
          content: String(input[start..<index]),
          range: start..<input.index(after: index)
        )
      }

      index = input.index(after: index)
    }

    return nil
  }

  private func parenthesizedContent(
    startingAt start: String.Index,
    in input: String
  ) -> Content? {
    var index = input.index(after: start)
    var depth = 0

    while index < input.endIndex {
      if input[index] == "\\" {
        index = input.index(after: index)
        if index < input.endIndex {
          index = input.index(after: index)
        }
        continue
      }

      if input[index] == "(" {
        depth += 1
      } else if input[index] == ")" {
        guard depth > 0 else {
          return Content(
            content: String(input[input.index(after: start)..<index]),
            range: start..<input.index(after: index)
          )
        }
        depth -= 1
      }

      index = input.index(after: index)
    }

    return nil
  }

  private func codeSpanRange(at index: String.Index, in input: String) -> Range<String.Index>? {
    guard input[index] == "`" else {
      return nil
    }

    let delimiter = backtickDelimiter(at: index, in: input)
    var cursor = delimiter.upperBound

    while cursor < input.endIndex {
      guard input[cursor] == "`" else {
        cursor = input.index(after: cursor)
        continue
      }

      let closingDelimiter = backtickDelimiter(at: cursor, in: input)
      if input[closingDelimiter] == input[delimiter] {
        return index..<closingDelimiter.upperBound
      }

      cursor = closingDelimiter.upperBound
    }

    return nil
  }

  private func codeFenceRange(at index: String.Index, in input: String) -> Range<String.Index>? {
    guard
      isLineStart(index, in: input),
      let openingFence = fence(at: index, in: input)
    else {
      return nil
    }

    var cursor = lineEnd(after: openingFence.range.upperBound, in: input)

    while cursor < input.endIndex {
      let lineStart = cursor

      if let closingFence = fence(at: lineStart, in: input),
        closingFence.marker == openingFence.marker,
        closingFence.length >= openingFence.length
      {
        return index..<lineEnd(after: closingFence.range.upperBound, in: input)
      }

      cursor = lineEnd(after: cursor, in: input)
    }

    return index..<input.endIndex
  }

  private func fence(at index: String.Index, in input: String) -> Fence? {
    var cursor = index
    var indentation = 0

    while cursor < input.endIndex, input[cursor] == " ", indentation < 4 {
      indentation += 1
      cursor = input.index(after: cursor)
    }

    guard indentation < 4, cursor < input.endIndex else {
      return nil
    }

    let marker = input[cursor]
    guard marker == "`" || marker == "~" else {
      return nil
    }

    var end = cursor
    var length = 0
    while end < input.endIndex, input[end] == marker {
      length += 1
      end = input.index(after: end)
    }

    guard length >= 3 else {
      return nil
    }

    return Fence(marker: marker, length: length, range: cursor..<end)
  }

  private func backtickDelimiter(
    at index: String.Index,
    in input: String
  ) -> Range<String.Index> {
    var end = index

    while end < input.endIndex, input[end] == "`" {
      end = input.index(after: end)
    }

    return index..<end
  }

  private func lineEnd(after index: String.Index, in input: String) -> String.Index {
    var cursor = index

    while cursor < input.endIndex {
      let next = input.index(after: cursor)
      if input[cursor] == "\n" {
        return next
      }
      cursor = next
    }

    return input.endIndex
  }

  private func isLineStart(_ index: String.Index, in input: String) -> Bool {
    index == input.startIndex || input[input.index(before: index)] == "\n"
  }

  private func token(for index: Int, in input: String) -> String {
    var token = "\u{E000}TEXTUAL_LINKED_IMAGE_\(index)\u{E000}"
    var offset = index

    while input.contains(token) {
      offset += 1
      token = "\u{E000}TEXTUAL_LINKED_IMAGE_\(offset)\u{E000}"
    }

    return token
  }

  private func destinationURL(from markdownDestination: String) -> URL? {
    guard let destination = firstDestination(in: markdownDestination) else {
      return nil
    }

    return URL(string: destination, relativeTo: baseURL)
  }

  private func firstDestination(in markdownDestination: String) -> String? {
    let trimmed = markdownDestination.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
      return nil
    }

    if trimmed.first == "<", let end = trimmed.dropFirst().firstIndex(of: ">") {
      return String(trimmed[trimmed.index(after: trimmed.startIndex)..<end])
    }

    var index = trimmed.startIndex

    while index < trimmed.endIndex {
      if trimmed[index] == "\\" {
        index = trimmed.index(after: index)
        if index < trimmed.endIndex {
          index = trimmed.index(after: index)
        }
        continue
      }

      if trimmed[index].isWhitespace {
        break
      }

      index = trimmed.index(after: index)
    }

    return String(trimmed[..<index])
  }
}

extension LinkedImageProcessor {
  struct Output {
    let markdown: String
    let links: [String: Link]
  }

  struct Link {
    let altText: String
    let destination: String
  }

  private struct LinkedImage {
    let range: Range<String.Index>
    let markdown: String
    let token: String
    let link: Link
  }

  private struct Content {
    let content: String
    let range: Range<String.Index>
  }

  private struct Fence {
    let marker: Character
    let length: Int
    let range: Range<String.Index>
  }
}
