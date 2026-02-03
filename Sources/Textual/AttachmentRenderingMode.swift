import SwiftUI

/// Defines how inline attachments are rendered in text.
public enum AttachmentRenderingMode: Sendable {
  /// Renders attachments using Canvas symbols (default).
  ///
  /// This mode is more performant as views are resolved once and drawn as symbols.
  /// Attachments are static and non-interactive in this mode.
  case canvas

  /// Renders attachments as live SwiftUI views positioned inline.
  ///
  /// This mode enables full interactivity (buttons, gestures, state updates) but may
  /// have slightly lower performance compared to Canvas rendering.
  case interactive
}

// MARK: - Environment Key

struct AttachmentRenderingModeKey: EnvironmentKey {
  static let defaultValue: AttachmentRenderingMode = .canvas
}

extension EnvironmentValues {
  var attachmentRenderingMode: AttachmentRenderingMode {
    get { self[AttachmentRenderingModeKey.self] }
    set { self[AttachmentRenderingModeKey.self] = newValue }
  }
}

// MARK: - View Extension

extension View {
  /// Sets the rendering mode for inline attachments.
  ///
  /// Use `.interactive` mode when your attachments need to respond to user input:
  ///
  /// ```swift
  /// InlineText(markdown: text)
  ///   .attachmentRenderingMode(.interactive)
  /// ```
  ///
  /// - Parameter mode: The rendering mode to use for attachments.
  /// - Returns: A view with the specified attachment rendering mode.
  public func attachmentRenderingMode(_ mode: AttachmentRenderingMode) -> some View {
    environment(\.attachmentRenderingMode, mode)
  }
}
