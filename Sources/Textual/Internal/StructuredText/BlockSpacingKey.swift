import SwiftUI

// MARK: - Overview
//
// A block sets its spacing with `textual.blockSpacing(_:)`, which a `BlockVStack` reads in two
// ways:
//
// - As container values, which the stack reads in the same pass as the block. `blockSpacing` holds
//   the spacing a block sets on its root view. `nestedBlockSpacing` holds the spacing of the blocks
//   inside a block, such as the paragraphs in a list or a block quote.
// - As a preference, which also reaches the stack from views inside containers, but only after the
//   first layout pass. When it arrives, it replaces the container values.

extension StructuredText {
  struct BlockSpacingKey: PreferenceKey, LayoutValueKey {
    static let defaultValue = BlockSpacing()

    static func reduce(value: inout BlockSpacing, nextValue: () -> BlockSpacing) {
      value = value.union(nextValue())
    }
  }
}

extension ContainerValues {
  @Entry var blockSpacing: StructuredText.BlockSpacing? = nil
  @Entry var nestedBlockSpacing = StructuredText.BlockSpacing()
}

extension Subview {
  /// The spacing the block sets on its root view, otherwise the spacing of the blocks inside it.
  var blockSpacing: StructuredText.BlockSpacing {
    containerValues.blockSpacing ?? containerValues.nestedBlockSpacing
  }
}

extension SubviewsCollection {
  /// The spacing of these blocks combined, which the block that contains them takes.
  var blockSpacing: StructuredText.BlockSpacing {
    reduce(StructuredText.BlockSpacing()) { $0.union($1.blockSpacing) }
  }
}
