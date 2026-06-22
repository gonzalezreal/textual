import SwiftUI

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
struct LinkAttribute: TextAttribute {
  var url: URL

  init(_ url: URL) {
    self.url = url
  }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension Text.Layout.Run {
  var url: URL? {
    self[LinkAttribute.self]?.url
  }
}
