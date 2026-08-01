import Testing

@testable import Textual

struct RevealClockTests {
  @Test func nominalRateWhenNoBacklog() {
    let configuration = RevealAnimation.default
    let rate = RevealClock.effectiveRate(
      backlogGlyphs: 0,
      isStreamEnding: false,
      configuration: configuration
    )

    #expect(rate == configuration.glyphsPerSecond)
  }

  @Test func nominalRateWhenBacklogWithinBudget() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 40
    configuration.maxBacklogDuration = 1.0

    // 20 glyphs at 40/s is 0.5s of backlog — within the 1.0s budget.
    let rate = RevealClock.effectiveRate(
      backlogGlyphs: 20,
      isStreamEnding: false,
      configuration: configuration
    )

    #expect(rate == 40)
  }

  @Test func boostedRateWhenBacklogExceedsBudget() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 40
    configuration.maxBacklogDuration = 0.5

    // 100 glyphs at 40/s is 2.5s of backlog — well past the 0.5s budget, so the rate should
    // speed up to clear it within budget: 100 / 0.5 = 200 glyphs/s.
    let rate = RevealClock.effectiveRate(
      backlogGlyphs: 100,
      isStreamEnding: false,
      configuration: configuration
    )

    #expect(rate == 200)
  }

  @Test func streamEndingOverridesBacklogBudget() {
    var configuration = RevealAnimation.default
    configuration.glyphsPerSecond = 40
    configuration.maxBacklogDuration = 5.0  // would normally tolerate this much backlog
    configuration.streamEndCatchUpDuration = 0.1

    let rate = RevealClock.effectiveRate(
      backlogGlyphs: 20,
      isStreamEnding: true,
      configuration: configuration
    )

    #expect(rate == 200)  // 20 / 0.1
  }

  @Test func streamEndingWithNoBacklogUsesNominalRate() {
    let configuration = RevealAnimation.default
    let rate = RevealClock.effectiveRate(
      backlogGlyphs: 0,
      isStreamEnding: true,
      configuration: configuration
    )

    #expect(rate == configuration.glyphsPerSecond)
  }

  @Test func revealedGlyphCountAdvancesLinearlyAndClampsToTarget() {
    #expect(
      RevealClock.revealedGlyphCount(anchorGlyphCount: 10, target: 100, rate: 20, elapsed: 1.0)
        == 30
    )
    #expect(
      RevealClock.revealedGlyphCount(anchorGlyphCount: 10, target: 20, rate: 20, elapsed: 1.0)
        == 20
    )
  }

  @Test func revealedGlyphCountIgnoresNegativeElapsed() {
    #expect(
      RevealClock.revealedGlyphCount(anchorGlyphCount: 10, target: 100, rate: 20, elapsed: -1.0)
        == 10
    )
  }
}
