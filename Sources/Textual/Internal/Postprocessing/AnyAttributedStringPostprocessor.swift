import SwiftUI

// MARK: - Overview
//
// `AnyAttributedStringPostprocessor` is a type-erased wrapper around any
// `AttributedStringPostprocessor`, used to store the postprocessor in `EnvironmentValues` while
// preserving `Equatable` semantics for `onChange`-driven invalidation.

struct AnyAttributedStringPostprocessor: AttributedStringPostprocessor {
  private let base: any AttributedStringPostprocessor

  init(_ base: some AttributedStringPostprocessor) {
    self.base = base
  }

  func postprocess(input: AttributedString) -> AttributedString {
    base.postprocess(input: input)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    AnyHashable(lhs.base) == AnyHashable(rhs.base)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

extension EnvironmentValues {
  @Entry var attributedStringPostprocessor: AnyAttributedStringPostprocessor = .init(
    IdentityAttributedStringPostprocessor()
  )
}

fileprivate struct IdentityAttributedStringPostprocessor: AttributedStringPostprocessor {
  func postprocess(input: AttributedString) -> AttributedString {
    input
  }
}
