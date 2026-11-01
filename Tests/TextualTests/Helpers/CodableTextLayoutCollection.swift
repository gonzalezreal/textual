#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SwiftUI

  @testable import Textual

  struct CodableTextLayoutCollection: Equatable, TextLayoutCollection {
    var layouts: [any Textual.TextLayout] {
      _layouts
    }

    let _layouts: [CodableTextLayout]

    func isEqual(to other: any Textual.TextLayoutCollection) -> Bool {
      _layouts == (other as? CodableTextLayoutCollection)?._layouts
    }

    func needsPositionReconciliation(with other: any Textual.TextLayoutCollection) -> Bool {
      false
    }

    func index(of layout: Text.Layout) -> Int? {
      nil
    }
  }

  extension CodableTextLayoutCollection {
    init(_ base: any TextLayoutCollection) {
      self.init(_layouts: base.layouts.map(CodableTextLayout.init))
    }
  }

  extension CodableTextLayoutCollection: Codable {
    init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      self._layouts = try container.decode([CodableTextLayout].self)
    }

    func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(_layouts)
    }
  }

  struct CodableTextLayout: Equatable, TextLayout {
    var lines: [any Textual.TextLine] {
      _lines
    }

    let attributedString: NSAttributedString
    let origin: CGPoint
    let bounds: CGRect
    let _lines: [CodableTextLine]
  }

  extension CodableTextLayout {
    init(_ base: any TextLayout) {
      self.init(
        attributedString: base.attributedString,
        origin: base.origin,
        bounds: base.bounds,
        _lines: base.lines.map(CodableTextLine.init)
      )
    }
  }

  extension CodableTextLayout: Codable {
    private enum CodingKeys: String, CodingKey {
      case attributedString, origin, bounds, lines
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.attributedString = try NSAttributedString(
        container.decode(AttributedString.self, forKey: .attributedString)
      )
      self.origin = try container.decode(CGPoint.self, forKey: .origin)
      self.bounds = try container.decode(CGRect.self, forKey: .bounds)
      self._lines = try container.decode([CodableTextLine].self, forKey: .lines)
    }

    func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(AttributedString(attributedString), forKey: .attributedString)
      try container.encode(origin, forKey: .origin)
      try container.encode(bounds, forKey: .bounds)
      try container.encode(_lines, forKey: .lines)
    }
  }

  struct CodableTextLine: Equatable, Codable, TextLine {
    private enum CodingKeys: String, CodingKey {
      case origin, typographicBounds
      case _runs = "runs"
    }

    var runs: [any Textual.TextRun] {
      _runs
    }

    let origin: CGPoint
    let typographicBounds: CGRect
    let _runs: [CodableTextRun]
  }

  extension CodableTextLine {
    init(_ base: any TextLine) {
      self.init(
        origin: base.origin,
        typographicBounds: base.typographicBounds,
        _runs: base.runs.map(CodableTextRun.init)
      )
    }
  }

  struct CodableTextRun: Equatable, Codable, TextRun {
    private enum CodingKeys: String, CodingKey {
      case isRightToLeft, typographicBounds, url, imageURL
      case _slices = "slices"
    }

    var layoutDirection: LayoutDirection {
      isRightToLeft ? .rightToLeft : .leftToRight
    }

    var slices: [any Textual.TextRunSlice] {
      _slices
    }

    let isRightToLeft: Bool
    let typographicBounds: CGRect
    let url: URL?
    var imageURL: URL? = nil
    var previewURL: URL? { imageURL ?? url }
    let _slices: [CodableTextRunSlice]
  }

  extension CodableTextRun {
    init(_ base: any TextRun) {
      self.init(
        isRightToLeft: base.layoutDirection == .rightToLeft,
        typographicBounds: base.typographicBounds,
        url: base.url,
        _slices: base.slices.map(CodableTextRunSlice.init)
      )
    }
  }

  struct CodableTextRunSlice: Equatable, Codable, TextRunSlice {
    let typographicBounds: CGRect
    let characterRange: Range<Int>
  }

  extension CodableTextRunSlice {
    init(_ base: any TextRunSlice) {
      self.init(
        typographicBounds: base.typographicBounds,
        characterRange: base.characterRange
      )
    }
  }
#endif
