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
    /// Actions the app adds to the selection menu, after the platform's own.
    var selectionActions: [TextSelectionAction]
    var selectionActionProminence: TextSelectionActionProminence

    weak var inputDelegate: (any UITextInputDelegate)?

    let logger = Logger(category: .textInteraction)

    private(set) lazy var _tokenizer = UITextInputStringTokenizer(textInput: self)
    private let selectionInteraction: UITextInteraction
    private(set) var outsideTapRecognizer: UITapGestureRecognizer?

    init(
      model: TextSelectionModel,
      exclusionRects: [CGRect],
      openURL: OpenURLAction,
      selectionActions: [TextSelectionAction] = [],
      selectionActionProminence: TextSelectionActionProminence = .standard
    ) {
      self.selectionActions = selectionActions
      self.selectionActionProminence = selectionActionProminence
      self.model = model
      self.exclusionRects = exclusionRects
      self.openURL = openURL
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
      let hasSelection = !(model.selectedRange?.isCollapsed ?? true)
      switch action {
      case #selector(copy(_:)), #selector(share(_:)):
        return hasSelection
      default:
        // Look up, translate, search and the rest are the platform's to offer for selected text; refusing
        // every unknown selector was what kept them off the menu.
        return hasSelection && super.canPerformAction(action, withSender: sender)
      }
    }

    // The edit menu for a text interaction is assembled through the context menu system, so this is where
    // the app's own actions join the platform's without replacing how the selection itself works.
    override func buildMenu(with builder: any UIMenuBuilder) {
      super.buildMenu(with: builder)
      guard builder.system == .context, !selectionActions.isEmpty, model.selectedRange?.isCollapsed == false else {
        return
      }
      // The text is only formatted once an action is chosen, and from the selection as it is then.
      let actions = selectionActions.map { action in
        UIAction(
          title: action.title,
          image: action.systemImage.map { UIImage(systemName: $0) } ?? nil
        ) { [weak self] _ in
          guard let self, let selectedRange = self.model.selectedRange, !selectedRange.isCollapsed else {
            return
          }
          action.handler(Formatter(self.model.attributedText(in: selectedRange)).plainText())
        }
      }
      builder.insertChild(
        UIMenu(options: .displayInline, children: actions),
        atEndOfMenu: .standardEdit
      )
      guard selectionActionProminence == .prominent else {
        return
      }
      // The assistant entry is a responder command, so it is found by what it does, not by a private identifier.
      builder.replaceChildren(ofMenu: .root) { children in
        children.movingAssistantEntryLast()
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

    /// A selection lives as long as its view is first responder, as it does in a text view: focusing a text field,
    /// presenting a sheet or leaving the screen ends it.
    override func resignFirstResponder() -> Bool {
      let resigned = super.resignFirstResponder()
      if resigned {
        model.selectedRange = nil
      }
      return resigned
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      updateOutsideTapRecognizer()
    }

    /// Ends the selection for a tap anywhere in the window but on this view; taps on the view are its own business.
    func dismissSelection(forTapAt point: CGPoint, in window: UIWindow) {
      guard model.selectedRange != nil, !bounds.contains(convert(point, from: window)) else {
        return
      }
      model.selectedRange = nil
    }

    // The recognizer sits on the window only while there is a selection, and lets every other touch through.
    private func updateOutsideTapRecognizer() {
      let recognizer = outsideTapRecognizer ?? makeOutsideTapRecognizer()
      let wantsRecognizer = model.selectedRange?.isCollapsed == false && window != nil
      if wantsRecognizer, recognizer.view !== window {
        recognizer.view?.removeGestureRecognizer(recognizer)
        window?.addGestureRecognizer(recognizer)
      } else if !wantsRecognizer, let view = recognizer.view {
        view.removeGestureRecognizer(recognizer)
      }
    }

    private func makeOutsideTapRecognizer() -> UITapGestureRecognizer {
      let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
      recognizer.cancelsTouchesInView = false
      recognizer.delaysTouchesEnded = false
      recognizer.delegate = self
      outsideTapRecognizer = recognizer
      return recognizer
    }

    @objc private func handleOutsideTap(_ gesture: UITapGestureRecognizer) {
      guard let window else {
        return
      }
      dismissSelection(forTapAt: gesture.location(in: window), in: window)
    }

    private func setUp() {
      model.selectionWillChange = { [weak self] in
        guard let self else { return }
        self.inputDelegate?.selectionWillChange(self)
      }
      model.selectionDidChange = { [weak self] in
        guard let self else { return }
        self.inputDelegate?.selectionDidChange(self)
        self.updateOutsideTapRecognizer()
      }

      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
      addGestureRecognizer(tapGesture)

      selectionInteraction.textInput = self
      selectionInteraction.delegate = self

      for gesture in selectionInteraction.gesturesForFailureRequirements {
        tapGesture.require(toFail: gesture)
      }

      addInteraction(selectionInteraction)
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
      logger.debug("interactionShouldBegin(at: \(point.logDescription)) -> true")
      return true
    }

    func interactionWillBegin(_ interaction: UITextInteraction) {
      logger.debug("interactionWillBegin")
      _ = self.becomeFirstResponder()
    }

    func interactionDidEnd(_ interaction: UITextInteraction) {
      logger.debug("interactionDidEnd")
    }
  }

  extension Logger.Textual.Category {
    fileprivate static let textInteraction = Self(rawValue: "textInteraction")
  }

  extension UITextInteractionView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      gestureRecognizer === outsideTapRecognizer
    }
  }
  extension UIMenuElement {
    /// Whether this element opens the system's writing assistant.
    fileprivate var isAssistantEntry: Bool {
      guard #available(iOS 18.2, *), let command = self as? UICommand else {
        return false
      }
      return command.action == #selector(UIResponder.showWritingTools(_:))
    }
  }

  extension [UIMenuElement] {
    /// The same elements with the assistant entry last, at this level and inside every menu, so that Copy and the
    /// app's own items keep their places wherever the system happens to file the entry.
    fileprivate func movingAssistantEntryLast() -> [UIMenuElement] {
      let reordered = map { element in
        (element as? UIMenu).map { menu in
          menu.replacingChildren(menu.children.movingAssistantEntryLast())
        } ?? element
      }
      return reordered.filter { !$0.isAssistantEntry } + reordered.filter { $0.isAssistantEntry }
    }
  }
#endif
