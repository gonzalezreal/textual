import SwiftUI
@_spi(Textual) private import SwiftUIMath

struct MathAttachment: Attachment {
  enum Style: Sendable {
    case inline
    case block
  }
  
  var description: String {
    switch style {
    case .inline:
      return "$\(latex)$"
    case .block:
      return "$$\(latex)$$"
    }
  }
  
  var selectionStyle: AttachmentSelectionStyle {
    .inline
  }
  
  private let latex: String
  private let style: Style
  
  init(latex: String, style: Style) {
    self.latex = latex
    self.style = style
  }
  
  var body: some View {
    MathView(latex: latex, style: style)
  }
  
  func baselineOffset(in environment: TextEnvironmentValues) -> CGFloat {
    -typographicBounds(in: environment).descent
  }
  
  func sizeThatFits(_ proposal: ProposedViewSize, in environment: TextEnvironmentValues) -> CGSize {
    typographicBounds(fitting: proposal, in: environment).size
  }
  
  private func typographicBounds(
    fitting proposal: ProposedViewSize = .unspecified,
    in environment: TextEnvironmentValues
  ) -> Math.TypographicBounds {
    Math.typographicBounds(
      for: latex,
      fitting: proposal,
      font: .init(
        name: .init(environment.mathProperties.fontName),
        size: FontScaled(environment.mathProperties.fontScale).resolve(in: environment)
      ),
      style: .init(style)
    )
  }
}

private struct MathView: View {
  @Environment(\.textEnvironment) private var environment
  
  let latex: String
  let style: MathAttachment.Style
  
  var body: some View {
    Math(latex)
      .mathFont(
        .init(
          name: .init(environment.mathProperties.fontName),
          size: FontScaled(environment.mathProperties.fontScale).resolve(in: environment)
        )
      )
      .mathTypesettingStyle(.init(style))
      .mathRenderingMode(.monochrome)
  }
}

extension Math.Font.Name {
  fileprivate init(_ fontName: MathProperties.FontName) {
    self.init(rawValue: fontName.rawValue)
  }
}

extension Math.TypesettingStyle {
  fileprivate init(_ style: MathAttachment.Style) {
    switch style {
    case .inline:
      self = .text
    case .block:
      self = .display
    }
  }
}
