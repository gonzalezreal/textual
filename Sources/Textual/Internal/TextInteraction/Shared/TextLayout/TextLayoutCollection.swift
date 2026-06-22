#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
protocol TextLayoutCollection {
    var layouts: [any TextLayout] { get }

    func isEqual(to other: any TextLayoutCollection) -> Bool
    func needsPositionReconciliation(with other: any TextLayoutCollection) -> Bool
    func index(of layout: Text.Layout) -> Int?
  }

@available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
struct AnyTextLayoutCollection: TextLayoutCollection, Equatable {
    private let base: any TextLayoutCollection

    init(_ base: any TextLayoutCollection) {
      self.base = base
    }

    var layouts: [any TextLayout] {
      base.layouts
    }

    func isEqual(to other: any TextLayoutCollection) -> Bool {
      base.isEqual(to: other)
    }

    func needsPositionReconciliation(with other: any TextLayoutCollection) -> Bool {
      base.needsPositionReconciliation(with: other)
    }

    func index(of layout: Text.Layout) -> Int? {
      base.index(of: layout)
    }

    static func == (lhs: AnyTextLayoutCollection, rhs: AnyTextLayoutCollection) -> Bool {
      lhs.isEqual(to: rhs.base)
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  protocol TextLayout {
    var attributedString: NSAttributedString { get }
    var origin: CGPoint { get }
    var bounds: CGRect { get }
    var lines: [any TextLine] { get }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  extension TextLayout {
    var frame: CGRect {
      bounds.offsetBy(dx: origin.x, dy: origin.y)
    }

    var runs: [any TextRun] {
      lines.flatMap(\.runs)
    }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  protocol TextLine {
    var origin: CGPoint { get }
    var typographicBounds: CGRect { get }
    var runs: [any TextRun] { get }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  protocol TextRun {
    var layoutDirection: LayoutDirection { get }
    var typographicBounds: CGRect { get }
    var url: URL? { get }
    var slices: [any TextRunSlice] { get }
  }

  @available(iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2, *)
  protocol TextRunSlice {
    var typographicBounds: CGRect { get }
    var characterRange: Range<Int> { get }
  }

#endif
