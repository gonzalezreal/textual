import SwiftUI
import Testing

@testable import Textual

struct RevealAnimationTests {
  @Test func defaultIsEnabled() {
    #expect(RevealAnimation.default.isEnabled)
  }

  @Test func disabledPresetIsNotEnabled() {
    #expect(!RevealAnimation.disabled.isEnabled)
  }

  @Test func disabledPresetOtherwiseMatchesDefault() {
    var expected = RevealAnimation.default
    expected.isEnabled = false

    #expect(RevealAnimation.disabled == expected)
  }

  @Test func defaultsAreReasonable() {
    let animation = RevealAnimation.default

    #expect(animation.glyphsPerSecond > 0)
    #expect((4...8).contains(animation.clusterSize))
    #expect(animation.fadeWindow > 0)
    #expect(animation.maxBacklogDuration > 0)
    #expect(animation.streamEndCatchUpDuration > 0)
    #expect(animation.streamEndCatchUpDuration < animation.maxBacklogDuration)
  }
}
