#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  struct EmptyTextLayoutCollection: TextLayoutCollection {
    var layouts: [any TextLayout] {
      []
    }

    func isEqual(to other: any TextLayoutCollection) -> Bool {
      other.layouts.isEmpty
    }

    func needsPositionReconciliation(with other: any TextLayoutCollection) -> Bool {
      false
    }

    func index(of layout: Text.Layout) -> Int? {
      nil
    }
  }
#endif
