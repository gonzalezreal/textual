import Foundation

/// Scales the current font by the given factor.
public struct FontScaleProperty: TextProperty {
  private let scale: CGFloat

  /// Creates a font scale property.
  public init(_ scale: CGFloat) {
    self.scale = scale
  }

  public func apply(in attributes: inout AttributeContainer, environment: TextEnvironmentValues) {
    let font = attributes.font ?? environment.font ?? .body
    #if compiler(>=6.2)
      if #available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *) {
        attributes.font = font.scaled(by: scale)
      } else if var provider = font.provider() {
        provider.scale = scale
        attributes.font = provider.resolve(in: environment)
      }
    #else
      if var provider = font.provider() {
        provider.scale = scale
        attributes.font = provider.resolve(in: environment)
      }
    #endif
  }
}

extension TextProperty where Self == FontScaleProperty {
  /// Scales the font by the given factor.
  public static func fontScale(_ scale: CGFloat) -> Self {
    FontScaleProperty(scale)
  }
}
