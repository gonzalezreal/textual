import Foundation

// MARK: - Overview
//
// `Memo` keeps the last value derived from an input. A view holds one in `@State` to derive a
// value in `body`, so the value is ready on the view's first layout pass and is derived again only
// when the input changes.
//
// Deriving in `body`, instead of writing `@State` from `onChange(of:initial:)`, matters when a
// container measures a view before its state settles. A `List` sizes its rows in a pass of their
// own, so a value that only arrives through `onChange` changes the row's height after the list
// measured it.

@MainActor
final class Memo<Input: Equatable, Output> {
  private var last: (input: Input, output: Output)?

  func value(for input: Input, derive: (Input) -> Output) -> Output {
    if let last, last.input == input {
      return last.output
    }

    let output = derive(input)
    last = (input, output)
    return output
  }
}
