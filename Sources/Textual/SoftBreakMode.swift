import SwiftUI

/// Controls how Textual renders soft breaks.
///
/// A soft break is a single newline inside a paragraph. Markdown renders it as a space, so text
/// written with one sentence per line reads as a single line. Use ``lineBreak`` to keep those
/// newlines.
///
/// You can set the mode using the ``TextualNamespace/softBreakMode(_:)`` modifier.
public enum SoftBreakMode: Hashable, Sendable {
  /// Renders a soft break as a space.
  case space
  /// Renders a soft break as a line break.
  case lineBreak
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var softBreakMode = SoftBreakMode.space
}
