import SwiftUI

extension StructuredText {
  /// A heading style inspired by GitHub’s rendering.
  public struct GitHubHeadingStyle: HeadingStyle {
    private static let fontScales: [CGFloat] = [2, 1.5, 1.25, 1, 0.875, 0.85]

    public func makeBody(configuration: Configuration) -> some View {
      let headingLevel = min(configuration.headingLevel, 6)
      let fontScale = Self.fontScales[headingLevel - 1]

      WithFontScaledValue(.fontScaled(0.3)) { spacing in
        VStack(alignment: .leading, spacing: spacing) {
          makeLabel(configuration: configuration)
            .textual.fontScale(fontScale)
            .textual.lineSpacing(.fontScaled(0.125))
            .fontWeight(.semibold)
          if headingLevel <= 2 {
            Divider()
              .overlay(DynamicColor.gitHubDivider)
          }
        }
        .textual.blockSpacing(.init(top: 24, bottom: 16))
      }
    }

    @ViewBuilder
    private func makeLabel(configuration: Configuration) -> some View {
      if min(configuration.headingLevel, 6) == 6 {
        configuration.label
          .foregroundStyle(DynamicColor.gitHubTertiary)
      } else {
        configuration.label
      }
    }
  }
}

extension StructuredText.HeadingStyle where Self == StructuredText.GitHubHeadingStyle {
  /// A GitHub-like heading style.
  public static var gitHub: Self {
    .init()
  }
}

#Preview {
  ScrollView {
    StructuredText(
      markdown: """
        Paragraph.
        # Heading 1
        Paragraph.
        ## Heading 2
        Paragraph.
        ### Heading 3
        Paragraph.
        #### Heading 4
        Paragraph.
        ##### Heading 5
        Paragraph.
        ###### Heading 6
        Paragraph.
        """
    )
    .padding()
  }
  .textual.headingStyle(.gitHub)
  .textual.paragraphStyle(.gitHub)
}
