import SwiftUI
import Testing

@testable import Textual

@MainActor
struct BuilderCacheTests {
  @Test func reusesTheBuilderForTheSameContentAndEnvironment() {
    let cache = TextFragment<AttributedString>.BuilderCache()
    let environment = TextEnvironmentValues()
    let first = cache.builder(for: AttributedString("Hello"), environment: environment)
    let second = cache.builder(for: AttributedString("Hello"), environment: environment)
    #expect(first === second)
  }

  @Test func rebuildsWhenTheEnvironmentChanges() {
    let cache = TextFragment<AttributedString>.BuilderCache()
    var environment = TextEnvironmentValues()
    let light = cache.builder(for: AttributedString("Hello"), environment: environment)
    environment.colorScheme = .dark
    let dark = cache.builder(for: AttributedString("Hello"), environment: environment)
    #expect(light !== dark)
  }
}
