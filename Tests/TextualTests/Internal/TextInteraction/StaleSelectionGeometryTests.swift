#if TEXTUAL_ENABLE_TEXT_SELECTION && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing

  @testable import Textual

  struct StaleSelectionGeometryTests {
    @Test
    func caretAfterLayoutReset() throws {
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let retainedStart = model.startPosition
      let retainedEnd = model.endPosition
      let retainedRange = TextRange(start: retainedStart, end: retainedEnd)
      model.setLayoutCollection(EmptyTextLayoutCollection())

      #expect(model.caretRect(for: retainedEnd) == .zero)
      #expect(model.firstRect(for: retainedRange).isNull)
      #expect(model.firstRect(for: TextRange(start: retainedEnd, end: retainedEnd)).isNull)
      #expect(model.selectionRects(for: retainedRange).isEmpty)
      #expect(model.text(in: retainedRange).isEmpty)
      #expect(model.positionAbove(retainedEnd, anchor: retainedStart) == nil)
      #expect(model.positionBelow(retainedStart, anchor: retainedEnd) == nil)
    }

    @Test(arguments: [
      IndexPath(layout: 99), IndexPath(line: 99, layout: 0), IndexPath(run: 99, line: 0, layout: 0),
      IndexPath(runSlice: 99, run: 0, line: 0, layout: 0),
    ])
    func rejectsStaleNestedPositions(indexPath: IndexPath) throws {
      // A replacement need not be empty: a retained line/run/slice may disappear
      // while its parent layout still exists. Test both invalid endpoints/anchors.
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let valid = model.startPosition
      let stale = TextPosition(indexPath: indexPath, affinity: .upstream)
      let range = TextRange(from: valid, to: stale)

      #expect(model.caretRect(for: stale) == .zero)
      #expect(model.firstRect(for: range).isNull)
      #expect(model.selectionRects(for: range).isEmpty)
      #expect(model.attributedText(in: range).length == 0)
      #expect(model.positionAbove(stale, anchor: valid) == nil)
      #expect(model.positionAbove(valid, anchor: stale) == nil)
      #expect(model.positionBelow(stale, anchor: valid) == nil)
      #expect(model.positionBelow(valid, anchor: stale) == nil)
      #expect(model.closestPosition(to: CGPoint(x: 20, y: 20), within: range) == nil)
      #expect(model.blockStart(for: stale) == nil)
      #expect(model.blockEnd(for: stale) == nil)
      #expect(model.blockRange(for: stale) == nil)
      #if os(macOS)
        #expect(model.wordRange(for: stale) == nil)
        #expect(model.nextWord(from: stale) == nil)
        #expect(model.previousWord(from: stale) == nil)
      #endif
    }

    @Test
    func linkAndSelectionWorkAfterLayoutIsRestored() throws {
      let url = try #require(
        Bundle.module.url(
          forResource: "Fixtures/TextSelectionModel/two-paragraphs-bidi", withExtension: "json"))
      let layouts = try JSONDecoder().decode(
        CodableTextLayoutCollection.self, from: Data(contentsOf: url))
      let model = TextSelectionModel(layoutCollection: layouts)
      model.setLayoutCollection(EmptyTextLayoutCollection())
      model.setLayoutCollection(layouts)
      let range = TextRange(start: model.startPosition, end: model.endPosition)

      #expect(model.url(for: CGPoint(x: 276, y: 25)) == URL(string: "https://example.com"))
      #expect(!model.selectionRects(for: range).isEmpty)
      #expect(!model.text(in: range).isEmpty)
      #expect(model.caretRect(for: model.endPosition) != .zero)
    }

    @Test(arguments: [false, true])
    func hitTestingEmptyRunsAndSlices(hasRun: Bool) {
      let rect = CGRect(x: 0, y: 0, width: 100, height: 20)
      let run = CodableTextRun(isRightToLeft: false, typographicBounds: rect, url: nil, _slices: [])
      let line = CodableTextLine(origin: .zero, typographicBounds: rect, _runs: hasRun ? [run] : [])
      let layout = CodableTextLayout(
        attributedString: NSAttributedString(), origin: .zero,
        bounds: rect, _lines: [line])
      let model = TextSelectionModel(
        layoutCollection: CodableTextLayoutCollection(_layouts: [layout]))

      #expect(model.closestPosition(to: CGPoint(x: 10, y: 10)) == nil)
      #expect(model.characterRange(at: CGPoint(x: 10, y: 10)) == nil)
    }

    #if os(iOS)
      @Test @MainActor
      func uiTextInputQueriesRetainedPositionsAfterReset() throws {
        let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
        let input = UITextInteractionView(
          model: model, exclusionRects: [],
          openURL: OpenURLAction { _ in .handled })
        let start = input.beginningOfDocument
        let end = input.endOfDocument
        let range = try #require(input.textRange(from: start, to: end))
        input.selectedTextRange = range
        model.setLayoutCollection(EmptyTextLayoutCollection())

        #expect(input.offset(from: start, to: end) == 0)
        #expect(input.caretRect(for: end) == .zero)
        #expect(input.firstRect(for: range).isNull)
        #expect(input.selectionRects(for: range).isEmpty)
        #expect(input.text(in: range) == "")
      }
    #endif
  }
#endif
