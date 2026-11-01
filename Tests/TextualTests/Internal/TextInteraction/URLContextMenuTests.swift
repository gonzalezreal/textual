#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI
  import Testing
  import UIKit

  @testable import Textual

  @MainActor struct URLContextMenuTests {
    @Test func menusOnlyReplaceSelectionAtHandledURLs() throws {
      let url = try #require(URL(string: "file:///maps/01%20Airport.png"))
      let bounds = CGRect(x: 0, y: 0, width: 100, height: 80)
      let run = CodableTextRun(isRightToLeft: false, typographicBounds: bounds,
                               url: nil, imageURL: url, _slices: [])
      let line = CodableTextLine(origin: .zero, typographicBounds: bounds, _runs: [run])
      let layout = CodableTextLayout(attributedString: NSAttributedString(string: "image"),
                                    origin: .zero, bounds: bounds, _lines: [line])
      let model = TextSelectionModel(layoutCollection: CodableTextLayoutCollection(_layouts: [layout]))
      let view = UITextInteractionView(model: model, exclusionRects: [], openURL: OpenURLAction { _ in .handled })
      let selection = UITextInteraction(for: .nonEditable)
      let interaction = UIContextMenuInteraction(delegate: view)
      let point = CGPoint(x: 40, y: 40)
      let nativeMenus = view.interactions.filter { $0 is UIContextMenuInteraction }.count
      #expect(view.interactionShouldBegin(selection, at: point))
      #expect(view.contextMenuInteraction(interaction, configurationForMenuAtLocation: point) == nil)
      view.menuProvider = URLContextMenuProvider { _ in nil }
      #expect(view.interactions.filter { $0 is UIContextMenuInteraction }.count == nativeMenus + 1)
      #expect(view.interactionShouldBegin(selection, at: point))
      view.menuProvider = URLContextMenuProvider { target in
        guard target.isFileURL else { return nil }
        return UIMenu(children: [UIAction(title: "Preview") { _ in }])
      }
      #expect(view.interactions.filter { $0 is UIContextMenuInteraction }.count == nativeMenus + 1)
      #expect(!view.interactionShouldBegin(selection, at: point))
      let configuration = try #require(view.contextMenuInteraction(interaction, configurationForMenuAtLocation: point))
      #expect(configuration.identifier as? NSURL == url as NSURL)
      let index = IndexPath(runSlice: 0, run: 0, line: 0, layout: 0)
      model.selectedRange = TextRange(start: .init(indexPath: index, affinity: .downstream),
                                     end: .init(indexPath: index, affinity: .upstream))
      #expect(view.interactionShouldBegin(selection, at: point))
      #expect(view.contextMenuInteraction(interaction, configurationForMenuAtLocation: point) == nil)
      model.selectedRange = nil
      #expect(view.interactionShouldBegin(selection, at: CGPoint(x: 110, y: 40)))
      #expect(view.contextMenuInteraction(interaction, configurationForMenuAtLocation: CGPoint(x: 110, y: 40)) == nil)
      view.menuProvider = nil
      #expect(view.interactions.filter { $0 is UIContextMenuInteraction }.count == nativeMenus)
    }
  }
#endif
