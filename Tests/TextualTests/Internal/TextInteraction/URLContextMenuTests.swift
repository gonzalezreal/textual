#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI
  import Testing
  import UIKit

  @testable import Textual

  @MainActor struct URLContextMenuTests {
    @Test(arguments: [false, true])
    func highlightMatchesThePressedImageRatherThanTheDocument(_ clipped: Bool) throws {
      let url = try #require(URL(string: "file:///map.png"))
      let bounds = CGRect(x: 0, y: 0, width: 100, height: 80)
      let run = CodableTextRun(isRightToLeft: false, typographicBounds: bounds,
                               url: nil, imageURL: url, _slices: [])
      let line = CodableTextLine(origin: .zero, typographicBounds: bounds, _runs: [run])
      let layout = CodableTextLayout(attributedString: NSAttributedString(string: "image"),
                                    origin: CGPoint(x: 20, y: 100), bounds: bounds, _lines: [line])
      let model = TextSelectionModel(layoutCollection: CodableTextLayoutCollection(_layouts: [layout]))
      let view = UITextInteractionView(model: model, exclusionRects: [], openURL: OpenURLAction { _ in .handled },
                                       menuProvider: URLContextMenuProvider { _ in UIMenu(children: []) })
      let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
      let controller = UIViewController()
      window.rootViewController = controller
      window.makeKeyAndVisible()
      defer { window.isHidden = true }
      let container = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: clipped ? 180 : 800))
      container.clipsToBounds = true
      container.backgroundColor = .systemBackground
      controller.view.addSubview(container)
      let image = UIView(frame: CGRect(x: 30, y: 120, width: 100, height: 80))
      image.backgroundColor = .label
      container.addSubview(image)
      view.frame = CGRect(x: 10, y: 20, width: 380, height: 4_000)
      container.addSubview(view)
      window.layoutIfNeeded()
      let interaction = UIContextMenuInteraction(delegate: view)
      let configuration = try #require(view.contextMenuInteraction(interaction,
        configurationForMenuAtLocation: CGPoint(x: 60, y: 140)))
      let delegate: any UIContextMenuInteractionDelegate = view
      let preview = try #require(delegate.contextMenuInteraction?(interaction, configuration: configuration,
        highlightPreviewForItemWithIdentifier: configuration.identifier))
      let size = CGSize(width: 100, height: clipped ? 60 : 80)
      #expect(preview.size == size)
      #expect(preview.target.container === view)
      #expect(preview.target.center == CGPoint(x: 70, y: clipped ? 130 : 140))
      model.setLayoutCollection(EmptyTextLayoutCollection())
      let dismissal = try #require(delegate.contextMenuInteraction?(interaction, configuration: configuration,
        dismissalPreviewForItemWithIdentifier: configuration.identifier))
      #expect(dismissal.size == size)
      #expect(dismissal.target.center == preview.target.center)
      view.removeFromSuperview()
      #expect(delegate.contextMenuInteraction?(interaction, configuration: configuration,
        dismissalPreviewForItemWithIdentifier: configuration.identifier) == nil)
    }

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
