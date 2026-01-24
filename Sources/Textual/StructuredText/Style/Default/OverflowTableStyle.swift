import SwiftUI

extension StructuredText {
  /// A table style that enables horizontal scrolling with a relative max width ratio.
  ///
  /// Use ``TextualNamespace/overflowMode(_:)`` to switch between scrolling and wrapping.
  public struct OverflowTableStyle: TableStyle {
    private static let borderWidth: CGFloat = 1

    private let relativeWidth: CGFloat

    /// Creates an overflow table style.
    ///
    /// - Parameter relativeWidth: The maximum width ratio relative to the scroll container width. Defaults to `1.5`.
    public init(relativeWidth: CGFloat = 1.5) {
      self.relativeWidth = relativeWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
      Overflow { state in
        let maxWidth = state.containerWidth.map {
          $0 * relativeWidth
        }
        configuration.label
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: maxWidth, alignment: .leading)
          .textual.tableOverlay { layout in
            Canvas { context, _ in
              for divider in layout.dividers() {
                context.fill(
                  Path(divider),
                  with: .style(DynamicColor.grayTertiary)
                )
              }
            }
          }
          .padding(Self.borderWidth)
      }
      .textual.tableCellSpacing(horizontal: Self.borderWidth, vertical: Self.borderWidth)
      .textual.blockSpacing(.fontScaled(top: 1.6, bottom: 1.6))
    }
  }
}

extension StructuredText.TableStyle where Self == StructuredText.OverflowTableStyle {
  /// A table style that enables horizontal scrolling with a relative max width.
  public static var overflow: Self {
    .init()
  }

  /// A table style that enables horizontal scrolling with a relative max width.
  ///
  /// - Parameter relativeWidth: The maximum width ratio relative to the scroll container width.
  public static func overflow(relativeWidth: CGFloat) -> Self {
    .init(relativeWidth: relativeWidth)
  }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
#Preview {
  StructuredText(
    markdown: """
      The sky above the port was the color of television, tuned to a dead channel.

      Sloth speed  | Description                           | Notes
      ------------ | ------------------------------------- | ---------------------------------------------
      `slow`       | Moves slightly faster than a snail    | Good for sightseeing along the waterfront.
      `medium`     | Moves at an average speed             | Balanced choice for day-to-day commuting.
      `fast`       | Moves faster than a hare              | Best for urgent deliveries across town.
      `supersonic` | Moves faster than the speed of sound  | Only for the bravest sloths.

      It was a bright cold day in April, and the clocks were striking thirteen.
      """
  )
  .padding()
  .textual.tableStyle(.overflow)
}
