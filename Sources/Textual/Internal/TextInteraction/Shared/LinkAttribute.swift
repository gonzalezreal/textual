import SwiftUI

struct LinkAttribute: TextAttribute {
  var url: URL

  init(_ url: URL) {
    self.url = url
  }
}

struct ImageURLAttribute: TextAttribute {
  var url: URL
}

extension Text.Layout.Run {
  var url: URL? {
    self[LinkAttribute.self]?.url
  }

  var previewURL: URL? {
    self[ImageURLAttribute.self]?.url ?? url
  }
}
