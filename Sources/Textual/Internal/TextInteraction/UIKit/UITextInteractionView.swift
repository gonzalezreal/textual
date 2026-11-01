#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI
  import os
  import UniformTypeIdentifiers

  // MARK: - Overview
  //
  // `UITextInteractionView` implements selection and link interaction on iOS-family platforms.
  //
  // The view sits in an overlay above one or more rendered `Text` fragments. It uses
  // `TextSelectionModel` to translate touch locations into URLs and selection ranges, and it
  // respects `exclusionRects` so embedded scrollable regions can continue to handle gestures.
  // Selection UI is provided by `UITextInteraction` configured for non-editable content.

  final class UITextInteractionView: UIView {
    override var canBecomeFirstResponder: Bool {
      true
    }

    var model: TextSelectionModel
    var exclusionRects: [CGRect]
    var openURL: OpenURLAction
    var menuProvider: URLContextMenuProvider? {
      didSet { updateContextMenuInteraction() }
    }

    weak var inputDelegate: (any UITextInputDelegate)?

    let logger = Logger(category: .textInteraction)

    private(set) lazy var _tokenizer = UITextInputStringTokenizer(textInput: self)
    private let selectionInteraction: UITextInteraction
    private lazy var contextMenuInteraction = UIContextMenuInteraction(delegate: self)

    init(
      model: TextSelectionModel,
      exclusionRects: [CGRect],
      openURL: OpenURLAction,
      menuProvider: URLContextMenuProvider? = nil
    ) {
      self.model = model
      self.exclusionRects = exclusionRects
      self.openURL = openURL
      self.menuProvider = menuProvider
      self.selectionInteraction = UITextInteraction(for: .nonEditable)

      super.init(frame: .zero)
      self.backgroundColor = .clear

      setUp()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
      for exclusionRect in exclusionRects {
        if exclusionRect.contains(point) {
          return false
        }
      }
      return super.point(inside: point, with: event)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
      switch action {
      case #selector(copy(_:)), #selector(share(_:)):
        return !(model.selectedRange?.isCollapsed ?? true)
      default:
        return false
      }
    }

    override func copy(_ sender: Any?) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      let attributedText = model.attributedText(in: selectedRange)
      let formatter = Formatter(attributedText)

      UIPasteboard.general.setItems(
        [
          [
            UTType.plainText.identifier: formatter.plainText(),
            UTType.html.identifier: formatter.html(),
          ]
        ]
      )
    }

    private func setUp() {
      model.selectionWillChange = { [weak self] in
        guard let self else { return }
        self.inputDelegate?.selectionWillChange(self)
      }
      model.selectionDidChange = { [weak self] in
        guard let self else { return }
        self.inputDelegate?.selectionDidChange(self)
      }

      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
      addGestureRecognizer(tapGesture)

      selectionInteraction.textInput = self
      selectionInteraction.delegate = self

      for gesture in selectionInteraction.gesturesForFailureRequirements {
        tapGesture.require(toFail: gesture)
      }

      addInteraction(selectionInteraction)
      updateContextMenuInteraction()
    }

    private func updateContextMenuInteraction() {
      if menuProvider != nil {
        if contextMenuInteraction.view == nil { addInteraction(contextMenuInteraction) }
      } else if contextMenuInteraction.view != nil {
        removeInteraction(contextMenuInteraction)
      }
    }

    func menu(at point: CGPoint) -> (URL, UIMenu)? {
      // Selection handles retain their gestures even when they overlap a URL.
      guard model.selectedRange?.isCollapsed ?? true else { return nil }
      guard let url = model.previewURL(for: point), let menu = menuProvider?.menu(url) else {
        return nil
      }
      return (url, menu)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
      let location = gesture.location(in: self)
      guard let url = model.url(for: location) else {
        model.selectedRange = nil
        return
      }
      openURL(url)
    }

    @objc private func share(_ sender: Any?) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      let attributedText = model.attributedText(in: selectedRange)
      let itemSource = TextActivityItemSource(attributedString: attributedText)

      let activityViewController = UIActivityViewController(
        activityItems: [itemSource],
        applicationActivities: nil
      )

      if let popover = activityViewController.popoverPresentationController {
        let rect =
          model.selectionRects(for: selectedRange)
          .last?.rect.integral ?? .zero
        popover.sourceView = self
        popover.sourceRect = rect
      }

      if let windowScene = window?.windowScene,
        let viewController = windowScene.windows.first?.rootViewController
      {
        viewController.present(activityViewController, animated: true)
      }
    }
  }

  extension UITextInteractionView: UITextInteractionDelegate {
    func interactionShouldBegin(_ interaction: UITextInteraction, at point: CGPoint) -> Bool {
      menu(at: point) == nil
    }

    func interactionWillBegin(_ interaction: UITextInteraction) {
      logger.debug("interactionWillBegin")
      _ = self.becomeFirstResponder()
    }

    func interactionDidEnd(_ interaction: UITextInteraction) {
      logger.debug("interactionDidEnd")
    }
  }

  extension UITextInteractionView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
      _ interaction: UIContextMenuInteraction,
      configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
      guard let (url, menu) = menu(at: location) else { return nil }
      return UIContextMenuConfiguration(identifier: url as NSURL, previewProvider: nil) { _ in menu }
    }
  }

  extension Logger.Textual.Category {
    fileprivate static let textInteraction = Self(rawValue: "textInteraction")
  }
#endif
