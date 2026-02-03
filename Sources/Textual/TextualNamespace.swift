import Foundation

/// A namespace for Textual-specific extensions.
///
/// Use `TextualNamespace` as a customization point for constrained extensions. By placing
/// modifiers and helpers under `.textual`, Textual avoids adding lots of methods directly to
/// `View` and other widely used types.
///
/// The general pattern is:
///
/// ```swift
/// // Add APIs under `.textual` for a specific kind of base.
/// extension TextualNamespace where Base: View {
///   func myModifier() -> some View { ... }
/// }
/// ```
///
/// SwiftUI views get the namespace through the ``SwiftUICore/View/textual`` property.
/// Other types can opt into it by conforming to ``TextualCompatible``.
public struct TextualNamespace<Base> {
  @usableFromInline var base: Base
  @inlinable public init(_ base: Base) { self.base = base }
}

extension TextualNamespace: Sendable where Base: Sendable {}

/// A type that opts into the `.textual` namespace.
///
/// Types that conform to `TextualCompatible` gain `textual` helpers on both the instance and the
/// type.
public protocol TextualCompatible {}

extension TextualCompatible {
  /// The `TextualNamespace` type for this conforming type.
  @inlinable public static var textual: TextualNamespace<Self>.Type {
    TextualNamespace<Self>.self
  }

  /// A `TextualNamespace` wrapper around this instance.
  @inlinable public var textual: TextualNamespace<Self> { .init(self) }
}
