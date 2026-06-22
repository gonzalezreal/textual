import SwiftUI

public struct SubviewGroup<Result: View>: View {
  private let content: AnyView
  private let transform: (_VariadicView.Children) -> Result

  public init<Content: View>(
    subviews content: Content,
    @ViewBuilder transform: @escaping (_VariadicView.Children) -> Result
  ) {
    self.content = AnyView(content)
    self.transform = transform
  }

  public var body: some View {
    _VariadicView.Tree(
      VariadicRoot(transform: transform)
    ) {
      content
    }
  }
}

private struct VariadicRoot<Result: View>: _VariadicView
    .MultiViewRoot
{
  let transform: (_VariadicView.Children) -> Result

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    transform(children)
  }
}
