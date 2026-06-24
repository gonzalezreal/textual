#if TEXTUAL_ENABLE_TEXT_SELECTION && os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
  import Testing
  import UIKit

  @testable import Textual

  @MainActor
  struct UITextInteractionViewTests {
    @Test
    func resignFirstResponderClearsSelection() throws {
      let model = try TextSelectionModel(fixtureName: "two-paragraphs-bidi")
      model.selectedRange = TextRange(start: model.startPosition, end: model.endPosition)

      let view = UITextInteractionView(
        model: model,
        exclusionRects: [],
        openURL: OpenURLAction { _ in .discarded }
      )

      let window = UIWindow(frame: UIScreen.main.bounds)
      let viewController = UIViewController()
      viewController.view.addSubview(view)
      window.rootViewController = viewController
      window.makeKeyAndVisible()
      defer { window.isHidden = true }

      #expect(model.selectedRange != nil)
      #expect(view.becomeFirstResponder())

      let didResign = view.resignFirstResponder()

      #expect(didResign)
      #expect(model.selectedRange == nil)
    }
  }
#endif
