#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import UIKit

  @available(iOS 18, *)
  final class TextSelectionRectBox: UITextSelectionRect {
    private let wrappedValue: TextSelectionRect

    override var description: String {
      wrappedValue.description
    }

    init(_ wrappedValue: TextSelectionRect) {
      self.wrappedValue = wrappedValue
    }

    override var rect: CGRect { wrappedValue.rect }
    override var writingDirection: NSWritingDirection {
      switch wrappedValue.layoutDirection {
      case .leftToRight:
        .leftToRight
      case .rightToLeft:
        .rightToLeft
      @unknown default:
        .natural
      }
    }
    override var containsStart: Bool { wrappedValue.containsStart }
    override var containsEnd: Bool { wrappedValue.containsEnd }
    override var isVertical: Bool { false }  // Not applicable for our use case
  }
#endif
