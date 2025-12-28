import SwiftUI

// MARK: - Overview
//
// Applies arbitrary font scaling. Uses Font.scaled(by:) on iOS 26+ where available.
// On earlier platforms, falls back to font reflection and manual scaling via FontProvider.
//
// If reflection fails (unknown provider type), the original unscaled font is returned.

struct FontScaleModifier: ViewModifier {
  @Environment(\.textEnvironment) private var environment

  private let scale: CGFloat

  private var font: Font {
    environment.font ?? .body
  }

  init(_ scale: CGFloat) {
    self.scale = scale
  }

  func body(content: Content) -> some View {
    #if compiler(>=6.2)
      if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        content.font(font.scaled(by: scale))
      } else {
        content.font(modifiedFont())
      }
    #else
      content.font(modifiedFont())
    #endif
  }

  private func modifiedFont() -> Font {
    guard scale != 1, var provider = font.provider() else {
      return font
    }

    provider.scale = scale
    return provider.resolve(in: environment)
  }
}
