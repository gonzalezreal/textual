import SwiftUI

#if canImport(UIKit)
  typealias PlatformImage = UIImage
#elseif canImport(AppKit)
  typealias PlatformImage = NSImage
#endif

extension PlatformImage {
  static func resolve(
    _ name: String,
    bundle: Bundle?,
    environment: ColorEnvironmentValues
  ) -> PlatformImage? {
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
      guard let appearance = NSAppearance(environment: environment) else {
        return nil
      }
      var image: NSImage?
      appearance.performAsCurrentDrawingAppearance {
        if let bundle, bundle != .main {
          image = bundle.image(forResource: name)
        } else {
          image = NSImage(named: name)
        }
      }
      return image
    #elseif canImport(UIKit) && !os(watchOS)
      PlatformImage(
        named: name,
        in: bundle,
        compatibleWith: UITraitCollection(userInterfaceStyle: .init(environment.colorScheme))
          .modifyingTraits { $0.accessibilityContrast = .init(environment.colorSchemeContrast) }
      )
    #else
      PlatformImage(named: name, in: bundle, with: nil)
    #endif
  }
}

extension SwiftUI.Image {
  init(_ platformImage: PlatformImage) {
    #if canImport(UIKit)
      self.init(uiImage: platformImage)
    #elseif canImport(AppKit)
      self.init(nsImage: platformImage)
    #endif
  }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
  extension NSAppearance {
    convenience init?(environment: ColorEnvironmentValues) {
      switch (environment.colorScheme, environment.colorSchemeContrast) {
      case (.light, .standard):
        self.init(named: .aqua)
      case (.dark, .standard):
        self.init(named: .darkAqua)
      case (.light, .increased):
        self.init(named: .accessibilityHighContrastAqua)
      case (.dark, .increased):
        self.init(named: .accessibilityHighContrastDarkAqua)
      case (_, _):
        self.init(named: .aqua)
      }
    }
  }
#endif
