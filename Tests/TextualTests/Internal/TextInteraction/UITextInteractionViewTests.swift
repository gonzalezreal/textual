#if TEXTUAL_ENABLE_TEXT_SELECTION && os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import UIKit

  @testable import Textual

  @MainActor
  struct UITextInteractionViewTests {
    private func makeSelectedView() throws -> (window: UIWindow, view: UITextInteractionView, model: TextSelectionModel) {
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      let view = UITextInteractionView(model: model, exclusionRects: [], openURL: OpenURLAction { _ in .handled })
      view.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
      window.addSubview(view)
      window.makeKeyAndVisible()
      model.selectedRange = TextRange(start: model.startPosition, end: model.endPosition)
      return (window, view, model)
    }

    @Test func copyKeepsTheSelection() throws {
      let (_, view, model) = try makeSelectedView()
      view.copy(nil)
      #expect(model.selectedRange != nil)
    }

    @Test func resigningFirstResponderEndsTheSelection() throws {
      let (_, view, model) = try makeSelectedView()
      #expect(view.becomeFirstResponder())
      #expect(model.selectedRange != nil)
      #expect(view.resignFirstResponder())
      #expect(model.selectedRange == nil)
    }

    @Test func tapsOutsideTheViewEndTheSelection() throws {
      let (window, view, model) = try makeSelectedView()
      view.dismissSelection(forTapAt: CGPoint(x: 10, y: 60), in: window)
      #expect(model.selectedRange != nil, "A tap on the view is handled by the view itself")
      view.dismissSelection(forTapAt: CGPoint(x: 10, y: 300), in: window)
      #expect(model.selectedRange == nil)
    }

    @Test func theOutsideTapRecognizerFollowsTheSelection() throws {
      let (window, view, model) = try makeSelectedView()
      #expect(view.outsideTapRecognizer?.view === window)
      model.selectedRange = nil
      #expect(view.outsideTapRecognizer?.view == nil)
    }
  }
#endif
