import SwiftUI

// MARK: - Overview
//
// `TextLinkInteraction` adds lightweight link tapping to a `Text` fragment.
//
// SwiftUI resolves a `Text.Layout` for each fragment and publishes it through the `Text.LayoutKey`
// preference. This modifier reads the anchored layout, converts tap locations to layout-local
// coordinates, and looks for the first run whose typographic bounds contains the tap. When a run
// has a `url`, the modifier invokes the environment’s `openURL` action.

struct TextLinkInteraction: ViewModifier {
  @Environment(\.openURL) private var openURL

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_LINKS
      if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
        content
          .overlayPreferenceValue(Text.LayoutKey.self) { value in
            if let anchoredLayout = value.first {
              GeometryReader { geometry in
                Color.clear
                  .contentShape(.rect)
                  .gesture(
                    tap(
                      origin: geometry[anchoredLayout.origin],
                      layout: anchoredLayout.layout
                    )
                  )
              }
            }
          }
      } else {
        content
      }
    #else
      content
    #endif
  }

  #if TEXTUAL_ENABLE_LINKS
    @available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
    private func tap(origin: CGPoint, layout: Text.Layout) -> some Gesture {
      SpatialTapGesture()
        .onEnded { value in
          let localPoint = CGPoint(
            x: value.location.x - origin.x,
            y: value.location.y - origin.y
          )
          let runs = layout.flatMap(\.self)
          let run = runs.first { run in
            run.typographicBounds.rect.contains(localPoint)
          }
          guard let url = run?.url else {
            return
          }
          openURL(url)
        }
    }
  #endif
}
