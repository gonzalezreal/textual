import Foundation

// MARK: - Overview
//
// RevealDiff compares the previous and current character sequence of a growing TextFragment to
// classify how its content changed since the last update, so the reveal clock in TextFragment
// knows whether to extend the current reveal, jump forward silently, or leave the already-
// revealed frontier alone.
//
// Markdown reparsing on each streaming flush can, rarely, alter text ahead of what's already been
// revealed (e.g. an emphasis marker resolving late) — RevealDiff distinguishes that from the
// common pure-append case, and from the "must never un-reveal already-seen text" case, using only
// the common-prefix length between the two character sequences.

enum RevealDiff {
  /// How a TextFragment's content changed since the previous update.
  enum Change: Equatable {
    /// The new content extends the previous content with no changes to existing characters.
    /// Reveal should extend toward `newCount`.
    case append(newCount: Int)

    /// The new content diverges from the previous content, but only past the already-revealed
    /// frontier. Reveal should extend toward `newCount`, same as a pure append.
    case reflowAheadOfFrontier(newCount: Int)

    /// The new content diverges from the previous content at or before the already-revealed
    /// frontier — text the user has already seen was altered. Reveal must not un-reveal; jump the
    /// anchor forward instantly to `safeCount`, then resume normal reveal toward `newCount`.
    case reflowBehindFrontier(safeCount: Int, newCount: Int)

    /// The visible characters are unchanged (e.g. an attachment resolved asynchronously, altering
    /// attributes but not characters). No reveal-state change needed.
    case unchanged
  }

  /// Classifies how `newCharacters` changed relative to `previousCharacters`, given how many
  /// glyphs have already been revealed.
  static func classify<Old: Collection, New: Collection>(
    previousCharacters: Old,
    newCharacters: New,
    revealedCount: Int
  ) -> Change where Old.Element == Character, New.Element == Character {
    let previousCount = previousCharacters.count
    let newCount = newCharacters.count
    let commonPrefix = commonPrefixLength(previousCharacters, newCharacters)

    if commonPrefix == previousCount, previousCount == newCount {
      return .unchanged
    }
    if commonPrefix == previousCount {
      return .append(newCount: newCount)
    }
    if commonPrefix >= revealedCount {
      return .reflowAheadOfFrontier(newCount: newCount)
    }
    return .reflowBehindFrontier(safeCount: commonPrefix, newCount: newCount)
  }

  /// Returns the number of leading elements `lhs` and `rhs` have in common.
  static func commonPrefixLength<C1: Collection, C2: Collection>(
    _ lhs: C1, _ rhs: C2
  ) -> Int where C1.Element == Character, C2.Element == Character {
    var count = 0
    var lhsIndex = lhs.startIndex
    var rhsIndex = rhs.startIndex

    while lhsIndex < lhs.endIndex, rhsIndex < rhs.endIndex, lhs[lhsIndex] == rhs[rhsIndex] {
      count += 1
      lhsIndex = lhs.index(after: lhsIndex)
      rhsIndex = rhs.index(after: rhsIndex)
    }

    return count
  }
}
