import Testing

@testable import Textual

struct RevealDiffTests {
  @Test func commonPrefixLengthOfIdenticalStrings() {
    #expect(RevealDiff.commonPrefixLength("hello", "hello") == 5)
  }

  @Test func commonPrefixLengthOfDivergentStrings() {
    #expect(RevealDiff.commonPrefixLength("hello world", "hello there") == 6)
  }

  @Test func commonPrefixLengthWithEmptyStrings() {
    #expect(RevealDiff.commonPrefixLength("", "hello") == 0)
    #expect(RevealDiff.commonPrefixLength("hello", "") == 0)
  }

  @Test func classifyPureAppend() {
    let change = RevealDiff.classify(
      previousCharacters: "Hello",
      newCharacters: "Hello, world",
      revealedCount: 3
    )

    #expect(change == .append(newCount: 12))
  }

  @Test func classifyUnchanged() {
    let change = RevealDiff.classify(
      previousCharacters: "Hello",
      newCharacters: "Hello",
      revealedCount: 3
    )

    #expect(change == .unchanged)
  }

  @Test func classifyReflowAheadOfFrontier() {
    // Not a pure append — "fox" at index 10 became "brown fox" — but the divergence point (10)
    // is still past what's already been revealed (5), so it's safe to treat like an append.
    let change = RevealDiff.classify(
      previousCharacters: "The quick fox",
      newCharacters: "The quick brown fox",
      revealedCount: 5
    )

    #expect(change == .reflowAheadOfFrontier(newCount: 19))
  }

  @Test func classifyReflowBehindFrontierNeverUnreveals() {
    // Divergence at index 3 ("Hel" matches, then "l" vs "p"), but the user has already been
    // shown up through index 5 — the reparse altered text the user has already perceived as
    // "typed."
    let change = RevealDiff.classify(
      previousCharacters: "Hello world",
      newCharacters: "Help world",
      revealedCount: 5
    )

    if case .reflowBehindFrontier(let safeCount, let newCount) = change {
      #expect(safeCount == 3)
      #expect(newCount == 10)
    } else {
      Issue.record("Expected .reflowBehindFrontier, got \(change)")
    }
  }
}
