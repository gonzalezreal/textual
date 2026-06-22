import SwiftUI

@available(iOS, introduced: 13.0, obsoleted: 18.0, message: "CGSize is Hashable by default in iOS 18")
@available(macOS, introduced: 10.15, obsoleted: 15.0, message: "CGSize is Hashable by default in macOS 15")
@available(watchOS, introduced: 6.0, obsoleted: 11.0, message: "CGSize is Hashable by default in watchOS 11")
@available(tvOS, introduced: 13.0, obsoleted: 18.0, message: "CGSize is Hashable by default in tvOS 18")
@available(visionOS, introduced: 1.0, obsoleted: 2.0, message: "CGSize is Hashable by default in visionOS 2")
extension CGSize: @retroactive Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(width)
    hasher.combine(height)
  }
}
