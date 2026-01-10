import Foundation

extension AttributedStringProtocol {
  var isMathBlock: Bool {
    let attachments = self.attachments()

    guard
      attachments.count == 1,
      let attachment = attachments.first?.base as? MathAttachment,
      case .block = attachment.displayStyle
    else {
      return false
    }

    return String(self.characters[...])
      .trimmingCharacters(in: .whitespacesAndNewlines) == "\u{FFFC}"
  }

  func attachments() -> Set<AnyAttachment> {
    uniqueValues(for: \.textual.attachment)
  }

  func containsValues<T>(for keyPaths: Set<KeyPath<AttributeContainer, T?>>) -> Bool {
    runs.contains { run in
      keyPaths.first { keyPath in
        run.attributes[keyPath: keyPath] != nil
      } != nil
    }
  }

  func uniqueValues<T: Hashable>(for keyPath: KeyPath<AttributeContainer, T?>) -> Set<T> {
    var values: Set<T> = []
    for run in runs {
      if let value = run.attributes[keyPath: keyPath] {
        values.insert(value)
      }
    }
    return values
  }

  func slugified() -> String {
    String(
      String(characters[...])
        .lowercased()
        .map { $0.isWhitespace ? "-" : $0 }
        .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        .split(separator: "-", omittingEmptySubsequences: true)
        .joined(separator: "-")
    )
  }
}

// MARK: - Iterable view into blocks
//
// BlockRuns segments an AttributedString into block-level runs based on PresentationIntent
// boundaries. Each BlockRun represents a contiguous range where the block-level intent
// (the intent component immediately before the parent intent in the hierarchy) remains constant.
//
// When the intent changes or becomes nil, a new boundary is recorded. This allows iterating
// over structural blocks (paragraphs, list items, table cells) without reconstructing the
// entire block tree.

extension AttributedStringProtocol {
  func blockRuns(parent: PresentationIntent.IntentType? = nil) -> AttributedString.BlockRuns {
    AttributedString.BlockRuns(attributedString: self, parent: parent)
  }
}

extension AttributedString {
  struct BlockRuns: RandomAccessCollection {
    struct BlockRun: Sendable {
      let intent: PresentationIntent.IntentType?
      let range: Range<AttributedString.Index>
    }

    private struct Boundary: Equatable {
      let index: AttributedString.Runs.Index
      let intent: PresentationIntent.IntentType?
    }

    typealias Element = BlockRun
    typealias Index = Int

    private let runs: AttributedString.Runs
    private let boundaries: [Boundary]

    init(
      attributedString: some AttributedStringProtocol,
      parent: PresentationIntent.IntentType?
    ) {
      self.runs = attributedString.runs

      var boundaries: [Boundary] = []
      var lastIntent: PresentationIntent.IntentType?

      for index in runs.indices {
        let intent = runs[index].presentationIntent?.intent(before: parent)

        // Record first run or whenever the intent changes (including nil values)
        if boundaries.isEmpty || intent != lastIntent {
          boundaries.append(.init(index: index, intent: intent))
          lastIntent = intent
        }
      }

      self.boundaries = boundaries
    }

    var startIndex: Index { boundaries.startIndex }
    var endIndex: Index { boundaries.endIndex }

    func index(after i: Index) -> Index {
      boundaries.index(after: i)
    }

    func index(before i: Index) -> Index {
      boundaries.index(before: i)
    }

    subscript(position: Index) -> BlockRun {
      let boundary = boundaries[position]
      let nextRunIndex =
        (position + 1 < boundaries.count)
        ? boundaries[position + 1].index
        : runs.endIndex
      let lastRunIndex = runs.index(before: nextRunIndex)
      let lowerBound = runs[boundary.index].range.lowerBound
      let upperBound = runs[lastRunIndex].range.upperBound

      return BlockRun(intent: boundary.intent, range: lowerBound..<upperBound)
    }
  }
}

extension PresentationIntent {
  fileprivate func intent(
    before intent: PresentationIntent.IntentType?
  ) -> PresentationIntent.IntentType? {
    guard let intent else {
      return components.last
    }

    guard
      let index = components.firstIndex(of: intent),
      index != components.startIndex
    else {
      return nil
    }

    return components[components.index(before: index)]
  }
}

// MARK: - NSAttributedString

extension NSAttributedString.Key: TextualCompatible {}

extension TextualNamespace where Base == NSAttributedString.Key {
  static var attachment: Base {
    .init(AttributeScopes.TextualAttributes.AttachmentAttribute.name)
  }

  static var presentationIntent: Base {
    .init(AttributeScopes.FoundationAttributes.PresentationIntentAttribute.name)
  }
}
