import Foundation

private class Token {}

extension Bundle {
  // NB: Alternative to `Bundle.module` that does not crash when the bundle is not found
  static let textual: Bundle? = {
    let bundleName = "textual_Textual"

    let overrides: [URL]
    #if DEBUG
      // The 'PACKAGE_RESOURCE_BUNDLE_PATH' name is preferred since the expected value is a path. The
      // check for 'PACKAGE_RESOURCE_BUNDLE_URL' will be removed when all clients have switched over.
      // This removal is tracked by rdar://107766372.
      if let override = ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_PATH"]
        ?? ProcessInfo.processInfo.environment["PACKAGE_RESOURCE_BUNDLE_URL"]
      {
        overrides = [URL(fileURLWithPath: override)]
      } else {
        overrides = []
      }
    #else
      overrides = []
    #endif

    let candidates =
      overrides + [
        // Bundle should be present here when the package is linked into an App.
        Bundle.main.resourceURL,

        // Bundle should be present here when the package is linked into a framework.
        Bundle(for: Token.self).resourceURL,

        // For command-line tools.
        Bundle.main.bundleURL,
      ]

    for candidate in candidates {
      let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
      if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
        return bundle
      }
    }

    return nil
  }()
}
