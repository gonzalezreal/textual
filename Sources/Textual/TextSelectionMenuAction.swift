#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit) && !targetEnvironment(macCatalyst)
  import CoreGraphics

  /// Plain-text information passed to a custom macOS text-selection menu action.
  public struct TextualTextSelection: Sendable {
    /// The selected text.
    public let text: String

    /// The text block containing the selection, when one can be resolved.
    public let surroundingText: String?

    /// The selection bounds in the interaction view's local coordinate space.
    public let selectionRect: CGRect

    /// Creates a selection value supplied to a custom context-menu action.
    public init(text: String, surroundingText: String?, selectionRect: CGRect) {
      self.text = text
      self.surroundingText = surroundingText
      self.selectionRect = selectionRect
    }
  }

  /// One application-defined action appended to Textual's macOS selection context menu.
  public struct TextSelectionMenuAction: Identifiable, Sendable {
    /// A stable identity used to route menu invocations.
    public let id: String

    private let makeTitle: @MainActor @Sendable (TextualTextSelection) -> String
    private let performAction: @MainActor @Sendable (TextualTextSelection) -> Void

    /// Creates an action with a fixed menu title.
    public init(
      id: String,
      title: String,
      perform: @escaping @MainActor @Sendable (TextualTextSelection) -> Void
    ) {
      self.id = id
      self.makeTitle = { _ in title }
      self.performAction = perform
    }

    /// Creates an action whose menu title is derived from the current selection.
    public init(
      id: String,
      title: @escaping @MainActor @Sendable (TextualTextSelection) -> String,
      perform: @escaping @MainActor @Sendable (TextualTextSelection) -> Void
    ) {
      self.id = id
      self.makeTitle = title
      self.performAction = perform
    }

    @MainActor
    func title(for selection: TextualTextSelection) -> String {
      makeTitle(selection)
    }

    @MainActor
    func perform(with selection: TextualTextSelection) {
      performAction(selection)
    }
  }
#endif
