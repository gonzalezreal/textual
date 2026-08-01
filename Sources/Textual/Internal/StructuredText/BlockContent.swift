import SwiftUI

extension StructuredText {
  struct BlockContent<Content: AttributedStringProtocol>: View {
    @Environment(\.textStreamingEnabled) private var textStreamingEnabled
    @Environment(\.revealAnimation) private var revealAnimation

    private let parent: PresentationIntent.IntentType?
    private let content: Content

    init(parent: PresentationIntent.IntentType? = nil, content: Content) {
      self.parent = parent
      self.content = content
    }

    var body: some View {
      let runs = content.blockRuns(parent: parent)

      BlockVStack {
        ForEach(runs.indices, id: \.self) { index in
          let run = runs[index]
          let blockContent = content[run.range]
          // Only the last block may still be growing (e.g. streamed from a language model) —
          // narrow textStreamingEnabled so every earlier, settled block pays no reveal-animation
          // cost and remains fully selectable. This narrowing composes through nested
          // BlockContent instances (lists, block quotes) automatically, since each level re-reads
          // its own inherited value and re-applies the same last-index check.
          let isActive = textStreamingEnabled && index == runs.indices.last

          Block(intent: run.intent, content: blockContent)
            .environment(\.textStreamingEnabled, isActive)
            // Companion height animation: as the active block grows to accommodate newly
            // streamed lines, animate the height change instead of snapping. A separate
            // mechanism from the glyph-level RevealTextRenderer — this is SwiftUI's standard
            // implicit geometry animation, scoped to just this block.
            .animation(
              isActive ? revealAnimation.heightAnimation : nil,
              value: blockContent.characters.count
            )
        }
      }
    }
  }
}

extension StructuredText {
  struct Block: View {
    private let intent: PresentationIntent.IntentType?
    private let content: AttributedSubstring

    init(intent: PresentationIntent.IntentType?, content: AttributedSubstring) {
      self.intent = intent
      self.content = content
    }

    var body: some View {
      switch intent?.kind {
      case .paragraph where content.isMathBlock:
        MathBlock(content)
      case .paragraph:
        Paragraph(content)
      case .header(let level):
        Heading(content, level: level)
      case .orderedList:
        OrderedList(intent: intent, content: content)
      case .unorderedList:
        UnorderedList(intent: intent, content: content)
      case .codeBlock(let languageHint) where languageHint?.lowercased() == "math":
        MathCodeBlock(content)
      case .codeBlock(let languageHint):
        CodeBlock(content, languageHint: languageHint)
      case .blockQuote:
        BlockQuote(intent: intent, content: content)
      case .thematicBreak:
        ThematicBreak(content)
      case .table(let columns):
        Table(intent: intent, content: content, columns: columns)
      default:
        Paragraph(content)
      }
    }
  }
}
