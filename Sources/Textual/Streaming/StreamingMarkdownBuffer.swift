import Foundation

/// A buffer that withholds incomplete Markdown constructs from streamed text until they resolve.
///
/// Feed newly-arrived chunks of Markdown source to ``append(_:)`` and render only the string it
/// returns. Markdown parsers — including Foundation's `AttributedString(markdown:)`, which
/// Textual's built-in parser uses — treat an unmatched delimiter (an unclosed `**`, `` ` ``, `[`,
/// or code fence) as literal text until it closes. Rendering raw streamed Markdown directly can
/// therefore briefly show delimiter characters that vanish once the construct completes.
/// `StreamingMarkdownBuffer` detects the common incomplete constructs — bold, italic, inline code,
/// fenced code blocks, and links/images — and holds back the tail until they resolve, so those
/// characters are never shown.
///
/// This is a plain value type used outside the view hierarchy — call it from your own
/// streaming/state-management code, not from a view body:
///
/// ```swift
/// var buffer = StreamingMarkdownBuffer()
/// // ...each time a new chunk arrives from your network layer:
/// visibleMarkdown = buffer.append(chunk)
/// // ...once the stream ends:
/// visibleMarkdown = buffer.flush()
/// ```
///
/// Detection is a lightweight heuristic scan of the trailing, not-yet-confirmed portion of the
/// source — not a full Markdown parser — so it won't catch every possible construct (escaped
/// delimiters like `\*` aren't specially recognized, for example), but it handles the common
/// streaming cases. A construct that never resolves (e.g. a stray `*` used for multiplication) is
/// released after ``pendingTimeout`` so it isn't hidden forever.
public struct StreamingMarkdownBuffer: Sendable {
  private var source: String
  private var safeEndIndex: String.Index
  private var pendingSince: Date?
  private let pendingTimeout: TimeInterval
  private let currentDate: @Sendable () -> Date

  /// Creates a streaming Markdown buffer.
  ///
  /// - Parameter pendingTimeout: How long an incomplete construct may stay withheld before it's
  ///   shown as-is anyway. Defaults to 2 seconds.
  public init(pendingTimeout: TimeInterval = 2.0) {
    self.init(pendingTimeout: pendingTimeout, currentDate: { Date() })
  }

  init(pendingTimeout: TimeInterval, currentDate: @escaping @Sendable () -> Date) {
    self.source = ""
    self.safeEndIndex = source.startIndex
    self.pendingTimeout = pendingTimeout
    self.currentDate = currentDate
  }

  /// Appends newly-arrived Markdown source and returns the longest prefix that's currently safe
  /// to render — i.e. contains no unmatched/incomplete Markdown construct.
  public mutating func append(_ chunk: String) -> String {
    source += chunk
    advanceSafeEndIndex()
    return String(source[..<safeEndIndex])
  }

  /// Releases any withheld tail immediately, returning the full source. Call this when streaming
  /// ends so nothing is left permanently hidden if a construct never resolves (e.g. the response
  /// ends mid-emphasis).
  public mutating func flush() -> String {
    safeEndIndex = source.endIndex
    pendingSince = nil
    return source
  }

  private mutating func advanceSafeEndIndex() {
    let newSafeEndIndex = Self.pendingStartIndex(in: source[safeEndIndex...]) ?? source.endIndex
    if newSafeEndIndex != safeEndIndex {
      safeEndIndex = newSafeEndIndex
      pendingSince = nil
    }

    guard safeEndIndex < source.endIndex else {
      pendingSince = nil
      return
    }

    if let pendingSince, currentDate().timeIntervalSince(pendingSince) > pendingTimeout {
      safeEndIndex = source.endIndex
      self.pendingSince = nil
    } else if pendingSince == nil {
      pendingSince = currentDate()
    }
  }

  /// Returns the index of the earliest unresolved Markdown construct in `text`, or `nil` if
  /// everything in `text` is safe to render as-is.
  static func pendingStartIndex(in text: Substring) -> String.Index? {
    var index = text.startIndex

    var codeFenceStart: String.Index?
    var codeSpanTickCount = 0
    var codeSpanStart: String.Index?
    var strongStart: String.Index?
    var emphasisStart: String.Index?
    var strongUnderscoreStart: String.Index?
    var emphasisUnderscoreStart: String.Index?
    var linkStart: String.Index?

    // Checked against `text.base` (the full source), not `text.startIndex`, so that re-scanning
    // from a mid-line `safeEndIndex` (e.g. right at a pending "**") never mistakes the rescan's
    // substring boundary for a genuine line start.
    func isAtLineStart(_ idx: String.Index) -> Bool {
      idx == text.base.startIndex || text.base[text.base.index(before: idx)] == "\n"
    }

    func runLength(of char: Character, at idx: String.Index) -> Int {
      var i = idx
      var count = 0
      while i < text.endIndex, text[i] == char {
        count += 1
        i = text.index(after: i)
      }
      return count
    }

    scan: while index < text.endIndex {
      let char = text[index]

      if codeFenceStart != nil {
        if char == "`", isAtLineStart(index), text[index...].hasPrefix("```") {
          codeFenceStart = nil
          index = text.index(index, offsetBy: 3)
        } else {
          index = text.index(after: index)
        }
        continue
      }

      if char == "`", isAtLineStart(index), text[index...].hasPrefix("```") {
        codeFenceStart = index
        index = text.index(index, offsetBy: 3)
        continue
      }

      if char == "`" {
        let length = runLength(of: "`", at: index)
        if codeSpanTickCount == 0 {
          codeSpanTickCount = length
          codeSpanStart = index
        } else if length == codeSpanTickCount {
          codeSpanTickCount = 0
          codeSpanStart = nil
        }
        index = text.index(index, offsetBy: length)
        continue
      }

      if codeSpanTickCount == 0 {
        if char == "*" || char == "_" {
          let length = runLength(of: char, at: index)
          let runEnd = text.index(index, offsetBy: length)
          let precededByWhitespace = index == text.startIndex || text[text.index(before: index)].isWhitespace
          let followedByWhitespace = runEnd == text.endIndex || text[runEnd].isWhitespace

          // A delimiter run flanked by whitespace on both sides (e.g. the "*" in "2 * 3") isn't
          // a valid emphasis/strong opener or closer per CommonMark's flanking rules — treat it
          // as plain text so legitimate uses (multiplication, etc.) aren't mistaken for pending
          // formatting.
          guard !(precededByWhitespace && followedByWhitespace) else {
            index = runEnd
            continue
          }

          let pairCount = length / 2
          let remainder = length % 2
          for _ in 0..<pairCount {
            if char == "*" {
              strongStart = (strongStart == nil) ? index : nil
            } else {
              strongUnderscoreStart = (strongUnderscoreStart == nil) ? index : nil
            }
          }
          if remainder == 1 {
            if char == "*" {
              emphasisStart = (emphasisStart == nil) ? index : nil
            } else {
              emphasisUnderscoreStart = (emphasisUnderscoreStart == nil) ? index : nil
            }
          }
          index = text.index(index, offsetBy: length)
          continue
        }

        if char == "[" {
          if linkStart == nil { linkStart = index }
          index = text.index(after: index)
          continue
        }
        if char == "!" {
          let next = text.index(after: index)
          if next < text.endIndex, text[next] == "[" {
            if linkStart == nil { linkStart = index }
            index = text.index(after: next)
            continue
          }
        }
        if char == "]", linkStart != nil {
          let afterBracket = text.index(after: index)
          if afterBracket < text.endIndex, text[afterBracket] == "(" {
            if let closeParen = text[afterBracket...].firstIndex(of: ")") {
              // Complete "[text](url)" — resolved.
              linkStart = nil
              index = text.index(after: closeParen)
              continue
            } else {
              // "[text](" started but no closing ")" yet — still pending. Nothing after this
              // point can be earlier than `linkStart`, so stop scanning.
              break scan
            }
          } else {
            // "]" not followed by "(" — just literal brackets, not a link attempt.
            linkStart = nil
            index = afterBracket
            continue
          }
        }
      }

      index = text.index(after: index)
    }

    let pendingPositions = [
      codeFenceStart, codeSpanStart, strongStart, emphasisStart,
      strongUnderscoreStart, emphasisUnderscoreStart, linkStart,
    ].compactMap(\.self)

    return pendingPositions.min()
  }
}
