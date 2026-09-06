import SwiftUI

/// An action offered on the menu for a text selection, alongside the platform's own.
///
/// The system already provides copying, sharing, look-up and translation for selected text; a selection
/// action adds what the app can do with that text (quote it, search it, save it) without replacing the
/// platform's selection handling.
public struct TextSelectionAction: Identifiable, Sendable {
  public let id: String
  /// The menu item's title.
  public let title: String
  /// The name of an SF Symbol shown with the title, where the platform's menu shows images.
  public let systemImage: String?
  /// Runs with the plain text of the selection when the item is chosen.
  public let handler: @MainActor @Sendable (String) -> Void

  public init(
    id: String? = nil,
    title: String,
    systemImage: String? = nil,
    handler: @escaping @MainActor @Sendable (String) -> Void
  ) {
    self.id = id ?? title
    self.title = title
    self.systemImage = systemImage
    self.handler = handler
  }
}

/// Where an app's actions sit on the selection menu relative to the system's.
public enum TextSelectionActionProminence: Sendable, Hashable {
  /// After the platform's edit actions, wherever the system puts them.
  case standard
  /// Right after Copy, ahead of the system's assistant entry, which moves to the end of the menu.
  ///
  /// On iOS 27 the assistant entry takes a slot on the menu's first page, which is short enough that
  /// an app's own item can end up behind the overflow chevron. Prominent actions come first instead.
  /// The macOS menu has no such entry, so there the two cases read the same.
  case prominent
}

extension EnvironmentValues {
  @Entry var textSelectionActions: [TextSelectionAction] = []
  @Entry var textSelectionActionProminence: TextSelectionActionProminence = .standard
}
