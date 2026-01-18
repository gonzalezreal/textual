import SwiftUI

extension StructuredText {
  /// A table style inspired by GitHub’s rendering.
  public struct GitHubTableStyle: TableStyle {
    private static let borderWidth: CGFloat = 1

    /// Creates the GitHub table style.
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
      configuration.label
        .textual.tableCellSpacing(horizontal: Self.borderWidth, vertical: Self.borderWidth)
        .textual.blockSpacing(.init(top: 0, bottom: 16))
        .padding(Self.borderWidth)
        .border(DynamicColor.gitHubBorder, width: Self.borderWidth)
    }

    public func makeBackground(layout: StructuredText.TableLayout) -> some View {
      Canvas { context, _ in
        for bounds in layout.evenRowBounds {
          context.fill(
            Path(bounds.integral),
            with: .style(DynamicColor.gitHubSecondaryBackground)
          )
        }
      }
    }

    public func makeOverlay(layout: StructuredText.TableLayout) -> some View {
      Canvas { context, _ in
        for divider in layout.dividers() {
          context.fill(
            Path(divider),
            with: .style(DynamicColor.gitHubBorder)
          )
        }
      }
    }
  }
}

extension StructuredText.TableLayout {
  fileprivate var evenRowBounds: [CGRect] {
    rowIndices
      .dropFirst()
      .filter { $0.isMultiple(of: 2) }
      .map { rowBounds($0) }
  }
}

extension StructuredText.TableStyle where Self == StructuredText.GitHubTableStyle {
  /// A GitHub-like table style.
  public static var gitHub: Self {
    .init()
  }
}

#Preview {
  StructuredText(
    markdown: """
      The sky above the port was the color of television, tuned to a dead channel.

      Sloth speed  | Description                          
      ------------ | ------------------------------------- 
      `slow`       | Moves slightly faster than a snail  
      `medium`     | Moves at an average speed           
      `fast`       | Moves faster than a hare            
      `supersonic` | Moves faster than the speed of sound

      It was a bright cold day in April, and the clocks were striking thirteen.
      """
  )
  .padding()
  .textual.inlineStyle(.gitHub)
  .textual.paragraphStyle(.gitHub)
  .textual.tableCellStyle(.gitHub)
  .textual.tableStyle(.gitHub)
}
