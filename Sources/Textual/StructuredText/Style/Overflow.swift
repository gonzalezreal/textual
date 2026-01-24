import SwiftUI

/// Controls how content behaves when it overflows horizontally.
public enum OverflowMode: Hashable {
  /// Wraps content to fit the available width.
  case wrap
  /// Allows horizontal scrolling.
  case scroll
}

/// Describes the current overflow behavior and available layout metrics.
public enum OverflowState: Hashable {
  /// Wraps content to fit the available width.
  case wrap
  /// Scrolls horizontally. The container width is provided when available.
  case scroll(containerWidth: CGFloat?)

  /// The scroll container width when available; otherwise `nil`.
  public var containerWidth: CGFloat? {
    guard case .scroll(let containerWidth) = self else {
      return nil
    }
    return containerWidth
  }
}

/// A container that adapts to the current ``OverflowMode``.
///
/// `Overflow` handles content that overflows horizontally. It can switch
/// between wrapping and horizontal scrolling based on an environment value.
///
/// You can set the mode using the ``TextualNamespace/overflowMode(_:)`` modifier. The default is
/// ``OverflowMode/scroll``.
///
/// - Note: You should always use `Overflow` if your custom style needs horizontal scrolling.
///   Using a horizontal `ScrollView` directly will interfere with text selection gestures.
public struct Overflow<Content: View>: View {
  @Environment(\.overflowMode) private var mode
  @State private var containerWidth: CGFloat?
  @State private var contentHeight: CGFloat?

  private let content: (OverflowState) -> Content

  /// Creates an overflow container.
  public init(@ViewBuilder content: @escaping () -> Content) {
    self.init { _ in
      content()
    }
  }

  /// Creates an overflow container that exposes the current overflow state.
  public init(@ViewBuilder content: @escaping (_ state: OverflowState) -> Content) {
    self.content = content
  }

  public var body: some View {
    switch mode {
    case .wrap:
      content(.wrap)
        .frame(maxWidth: .infinity, alignment: .leading)

    case .scroll:
      ScrollView(.horizontal) {
        ZStack {
          // Update the scroll view height when the content height changes
          Color.clear
            .frame(minHeight: contentHeight)
          content(.scroll(containerWidth: containerWidth))
            .onGeometryChange(for: CGFloat.self, of: \.size.height) {
              contentHeight = $0
            }
            // Make text selection local in scrollable regions
            .modifier(TextSelectionInteraction())
            .transformPreference(Text.LayoutKey.self) { value in
              value = []
            }
        }
      }
      .onScrollGeometryChange(for: CGFloat.self, of: \.containerSize.width) {
        containerWidth = $1
      }
      // Propagate gesture exclusion area
      .background(
        GeometryReader { geometry in
          Color.clear
            .preference(
              key: OverflowFrameKey.self,
              value: [geometry.frame(in: .textContainer)]
            )
        }
      )
    }
  }
}

extension EnvironmentValues {
  @usableFromInline
  @Entry var overflowMode = OverflowMode.scroll
}
