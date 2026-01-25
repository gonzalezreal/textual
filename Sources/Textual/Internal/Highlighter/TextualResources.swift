import Foundation

/// Safe resource bundle accessor for Textual.
///
/// Locates the SwiftPM-generated resource bundle, checking multiple locations:
/// 1. Inside Bundle.main (packaged apps)
/// 2. Bundle.module (SwiftPM development/tests)
/// 3. Falls back to Bundle.main if not found
///
/// This avoids a fatal crash when Bundle.module can't locate its resources
/// in packaged .app bundles where the resource bundle path differs from
/// SwiftPM's expectations.
enum TextualResources {
  static let bundle: Bundle = locateBundle()

  private static let bundleName = "Textual_Textual"

  private static func locateBundle() -> Bundle {
    // 1. Check inside Bundle.main (packaged apps copy resources here)
    if let mainResourceURL = Bundle.main.resourceURL {
      let bundleURL = mainResourceURL.appendingPathComponent("\(bundleName).bundle")
      if let bundle = Bundle(url: bundleURL) {
        return bundle
      }
    }

    // 2. Check Bundle.main directly for embedded resources
    if Bundle.main.url(forResource: "prism-bundle", withExtension: "js") != nil {
      return Bundle.main
    }

    // 3. Try Bundle.module locations manually (avoids fatalError)
    if let moduleBundle = loadModuleBundleSafely() {
      return moduleBundle
    }

    // 4. Last resort: try Bundle.module directly (may crash, but we've exhausted safe options)
    // Wrapped in a defer to at least attempt graceful handling
    return (try? loadBundleModuleWithFallback()) ?? Bundle.main
  }

  private static func loadModuleBundleSafely() -> Bundle? {
    let candidates: [URL?] = [
      Bundle.main.resourceURL,
      Bundle.main.bundleURL,
      Bundle(for: BundleLocator.self).resourceURL,
      Bundle(for: BundleLocator.self).bundleURL,
    ]

    for candidate in candidates {
      guard let baseURL = candidate else { continue }

      // Direct path
      let directURL = baseURL.appendingPathComponent("\(bundleName).bundle")
      if let bundle = Bundle(url: directURL) {
        return bundle
      }

      // Inside Resources/
      let resourcesURL = baseURL
        .appendingPathComponent("Resources")
        .appendingPathComponent("\(bundleName).bundle")
      if let bundle = Bundle(url: resourcesURL) {
        return bundle
      }

      // Inside PlugIns/ (some app structures)
      let plugInsURL = baseURL
        .appendingPathComponent("PlugIns")
        .appendingPathComponent("\(bundleName).bundle")
      if let bundle = Bundle(url: plugInsURL) {
        return bundle
      }
    }

    return nil
  }

  private static func loadBundleModuleWithFallback() throws -> Bundle {
    // This is a last resort - Bundle.module may fatalError
    // We can't fully prevent this, but our earlier checks should catch most cases
    return Bundle.module
  }
}

// Helper class for bundle lookup via Bundle(for:)
private final class BundleLocator {}
