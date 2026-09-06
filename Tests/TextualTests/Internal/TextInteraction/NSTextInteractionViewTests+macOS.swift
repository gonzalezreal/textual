#if TEXTUAL_ENABLE_TEXT_SELECTION && os(macOS)
  import AppKit
  import SwiftUI
  import Testing

  @testable import Textual

  @MainActor
  struct NSTextInteractionViewTests {
    private func makeSelectedView() throws -> (window: NSWindow, view: NSTextInteractionView, model: TextSelectionModel) {
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let view = NSTextInteractionView(model: model, exclusionRects: [], openURL: OpenURLAction { _ in .handled })
      view.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
      let window = NSWindow(
        contentRect: CGRect(x: 0, y: 0, width: 320, height: 480), styleMask: .borderless, backing: .buffered, defer: false
      )
      window.contentView?.addSubview(view)
      model.selectedRange = TextRange(start: model.startPosition, end: model.endPosition)
      return (window, view, model)
    }

    private func click(at point: CGPoint, in window: NSWindow) -> NSEvent {
      try! #require(
        NSEvent.mouseEvent(
          with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0, windowNumber: window.windowNumber,
          context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        )
      )
    }

    @Test func resigningFirstResponderEndsTheSelection() throws {
      let (window, view, model) = try makeSelectedView()
      #expect(window.makeFirstResponder(view))
      #expect(model.selectedRange != nil)
      #expect(window.makeFirstResponder(nil))
      #expect(model.selectedRange == nil)
    }

    @Test func clicksOutsideTheViewEndTheSelection() throws {
      let (window, view, model) = try makeSelectedView()
      view.dismissSelection(forClickIn: click(at: CGPoint(x: 10, y: 60), in: window))
      #expect(model.selectedRange != nil, "A click on the view is handled by the view itself")
      view.dismissSelection(forClickIn: click(at: CGPoint(x: 10, y: 400), in: window))
      #expect(model.selectedRange == nil)
    }
  }
#endif
