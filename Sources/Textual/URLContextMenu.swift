#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI
  import UIKit

  extension TextualNamespace where Base: View {
    /// Adds a native context menu to links and embedded images on iOS.
    ///
    /// Return `nil` for URLs that should retain ordinary text selection. The provider builds
    /// the menu without performing its actions. It can be called while resolving selection.
    /// For an image wrapped in a link, the menu receives the image URL. Taps still open the link.
    /// Text selection must be enabled with ``textSelection(_:)``.
    /// An existing text selection keeps its gestures until the selection is cleared.
    ///
    /// ```swift
    /// StructuredText(markdown: markdown)
    ///   .textual.textSelection(.enabled)
    ///   .textual.urlContextMenu { url in
    ///     UIMenu(children: [UIAction(title: "Copy URL") { _ in UIPasteboard.general.url = url }])
    ///   }
    /// ```
    @MainActor public func urlContextMenu(
      _ menu: @escaping @MainActor @Sendable (URL) -> UIMenu?
    ) -> some View {
      base.environment(\.urlContextMenuProvider, URLContextMenuProvider(menu: menu))
    }
  }

  struct URLContextMenuProvider: Sendable {
    let menu: @MainActor @Sendable (URL) -> UIMenu?
  }

  extension EnvironmentValues {
    @Entry var urlContextMenuProvider: URLContextMenuProvider? = nil
  }
#endif
