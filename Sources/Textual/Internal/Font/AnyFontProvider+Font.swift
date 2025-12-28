import ConcurrencyExtras
import SwiftUI

// MARK: - Overview
//
// Font reflection enables arbitrary scaling of SwiftUI.Font while preserving modifiers. SwiftUI
// does not expose a scaling API, so we reflect Font's internal provider structure and wrap it
// in a FontProvider that can compute environment-aware sizes and produce scaled Font instances.
//
// This approach is inspired by https://movingparts.io/fonts-in-swiftui
//
// Font.provider() reflects a Font using Mirror, recognizes known provider types (TextStyleProvider,
// SystemProvider, NamedProvider, PlatformFontProvider) and modifier chains (bold, italic, monospaced,
// weight, width, leading, scaled), then caches the resulting AnyFontProvider by font hash.
//
// Font internals are stable across OS versions, but new font modifiers introduced in future releases
// won't be recognized. When reflection encounters an unknown provider type, provider() returns nil
// and font scaling gracefully falls back to the original unscaled font.

extension Font {
  fileprivate typealias ProviderCache = NSCache<KeyBox<Font>, Box<AnyFontProvider>>
}

extension Font.ProviderCache {
  fileprivate static var `default`: Self {
    let cache = Self()
    cache.countLimit = 100
    return cache
  }
}

extension Font {
  private static let providerCache = LockIsolated(ProviderCache.default)

  func provider() -> AnyFontProvider? {
    Self.providerCache.withValue {
      let cacheKey = KeyBox(self)
      if let provider = $0.object(forKey: cacheKey) {
        return provider.wrappedValue
      } else {
        if let provider = AnyFontProvider(font: self) {
          $0.setObject(Box(provider), forKey: cacheKey)
          return provider
        } else {
          return nil
        }
      }
    }
  }
}

extension AnyFontProvider {
  init?(font: Font) {
    let mirror = Mirror(reflecting: font)

    guard let provider = mirror.descendant("provider", "base") else {
      return nil
    }

    self.init(reflecting: provider)
  }

  private init?(reflecting provider: Any) {
    let mirror = Mirror(reflecting: provider)
    let type = String(describing: mirror.subjectType)

    // Match known SwiftUI provider types by name and extract their properties
    switch type {
    //
    // Providers
    //

    case "TextStyleProvider":
      guard let style = mirror.descendant("style") as? Font.TextStyle else {
        return nil
      }
      self.init(
        TextStyleFontProvider(
          style: style,
          design: mirror.descendant("design") as? Font.Design,
          weight: mirror.descendant("weight") as? Font.Weight
        )
      )
    case "SystemProvider":
      guard let size = mirror.descendant("size") as? CGFloat else {
        return nil
      }
      self.init(
        SystemFontProvider(
          size: size,
          weight: mirror.descendant("weight") as? Font.Weight,
          design: mirror.descendant("design") as? Font.Design
        )
      )
    case "NamedProvider":
      guard
        let name = mirror.descendant("name") as? String,
        let size = mirror.descendant("size") as? CGFloat
      else {
        return nil
      }
      self.init(
        NamedFontProvider(
          name: name,
          size: size,
          textStyle: mirror.descendant("textStyle") as? Font.TextStyle
        )
      )
    case "PlatformFontProvider":
      guard let font = mirror.descendant("font") as? PlatformFont else {
        return nil
      }
      self.init(PlatformFontProvider(font: font))

    //
    // Modifiers
    //

    case "StaticModifierProvider<BoldModifier>":
      guard
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(StaticFontModifierProvider(BoldFontModifier.self, base: baseProvider))
    case "StaticModifierProvider<ItalicModifier>":
      guard
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(StaticFontModifierProvider(ItalicFontModifier.self, base: baseProvider))
    case "StaticModifierProvider<MonospacedModifier>":
      guard
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(StaticFontModifierProvider(MonospacedFontModifier.self, base: baseProvider))
    case "StaticModifierProvider<MonospacedDigitModifier>":
      guard
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(
        StaticFontModifierProvider(MonospacedDigitFontModifier.self, base: baseProvider)
      )
    case "ModifierProvider<FeatureSettingModifier>":
      guard
        let modifierMirror = mirror.descendant("modifier").map(Mirror.init(reflecting:)),
        let type = modifierMirror.descendant("type") as? Int,
        let selector = modifierMirror.descendant("selector") as? Int,
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }

      // NB: font.smallCaps() == font.lowercaseSmallCaps().uppercaseSmallCaps()

      switch (type, selector) {
      case (37, 1):  // lowercaseSmallCaps
        self.init(
          StaticFontModifierProvider(
            LowercaseSmallCapsFontModifier.self, base: baseProvider
          )
        )
      case (38, 1):  // uppercaseSmallCaps
        self.init(
          StaticFontModifierProvider(
            UppercaseSmallCapsFontModifier.self, base: baseProvider
          )
        )
      default:
        self = baseProvider
      }
    case "ModifierProvider<WeightModifier>":
      guard
        let modifierMirror = mirror.descendant("modifier").map(Mirror.init(reflecting:)),
        let weight = modifierMirror.descendant("weight") as? Font.Weight,
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(
        FontModifierProvider(
          base: baseProvider, modifier: WeightFontModifier(weight: weight)
        )
      )
    case "ModifierProvider<WidthModifier>":
      guard
        let modifierMirror = mirror.descendant("modifier").map(Mirror.init(reflecting:)),
        let value = modifierMirror.descendant("width") as? CGFloat,
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(
        FontModifierProvider(
          base: baseProvider, modifier: WidthFontModifier(width: .init(value))
        )
      )
    case "ModifierProvider<LeadingModifier>":
      guard
        let modifierMirror = mirror.descendant("modifier").map(Mirror.init(reflecting:)),
        let leading = modifierMirror.descendant("leading") as? Font.Leading,
        let base = mirror.descendant("base", "provider", "base"),
        let baseProvider = AnyFontProvider(reflecting: base)
      else {
        return nil
      }
      self.init(
        FontModifierProvider(
          base: baseProvider, modifier: LeadingFontModifier(leading: leading)
        )
      )
    #if compiler(>=6.2)
      case "ModifierProvider<ScalePointSizeModifier>":
        guard
          #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *),
          let modifierMirror = mirror.descendant("modifier").map(Mirror.init(reflecting:)),
          let scaleFactor = modifierMirror.descendant("scaleFactor") as? CGFloat,
          let base = mirror.descendant("base", "provider", "base"),
          let baseProvider = AnyFontProvider(reflecting: base)
        else {
          return nil
        }
        self.init(
          FontModifierProvider(
            base: baseProvider, modifier: ScaleFontModifier(scaleFactor: scaleFactor)
          )
        )
    #endif
    default:
      return nil
    }
  }
}
