import SwiftUI

enum DemoItem: String, CaseIterable, Hashable {
  case inlineText
  case structuredText
  case headings
  case lists
  case blockQuotes
  case codeBlocks
  case attachmentLoaders
  case tables
  case mathExpressions
  case gitHubReadme
}

extension DemoItem: Identifiable {
  var id: String {
    rawValue
  }
}

extension DemoItem {
  var label: Label<Text, Image> {
    switch self {
    case .inlineText:
      return Label("Inline Text", systemImage: "textformat.abc")
    case .structuredText:
      return Label("Structured Text", systemImage: "character.text.justify")
    case .headings:
      return Label("Headings", systemImage: "textformat.size")
    case .lists:
      return Label("Lists", systemImage: "list.bullet")
    case .blockQuotes:
      return Label("Block Quotes", systemImage: "text.quote")
    case .codeBlocks:
      return Label("Code Blocks", systemImage: "curlybraces")
    case .attachmentLoaders:
      return Label("Attachment Loaders", systemImage: "rectangle.on.rectangle")
    case .tables:
      return Label("Tables", systemImage: "tablecells")
    case .mathExpressions:
      return Label("Math Expressions", systemImage: "x.squareroot")
    case .gitHubReadme:
      return Label("GitHub `README`", systemImage: "doc.text")
    }
  }

  @ViewBuilder
  var destination: some View {
    switch self {
    case .inlineText:
      InlineTextDemo()
        .navigationTitle("Inline Text")
    case .structuredText:
      StructuredTextDemo()
        .navigationTitle("Structured Text")
    case .headings:
      HeadingDemo()
        .navigationTitle("Headings")
    case .lists:
      ListDemo()
        .navigationTitle("Lists")
    case .blockQuotes:
      BlockQuoteDemo()
        .navigationTitle("Block Quotes")
    case .codeBlocks:
      CodeBlockDemo()
        .navigationTitle("Code Blocks")
    case .attachmentLoaders:
      AttachmentLoaderDemo()
        .navigationTitle("Attachment Loaders")
    case .tables:
      TableDemo()
        .navigationTitle("Tables")
    case .mathExpressions:
      MathExpressionDemo()
        .navigationTitle("Math Expressions")
    case .gitHubReadme:
      GitHubReadmeDemo()
        .navigationTitle("GitHub README")
    }
  }
}

struct DemoSplitView: View {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @State private var selection: DemoItem?

  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        ForEach(DemoItem.allCases) { item in
          item.label
            .tag(item)
        }
      }
      .listStyle(.sidebar)
      .navigationTitle("Textual")
    } detail: {
      detail
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    .onAppear {
      if selection == nil, horizontalSizeClass == .regular {
        selection = .inlineText
      }
    }
  }

  @ViewBuilder
  private var detail: some View {
    if let selection {
      selection.destination
    } else {
      ContentUnavailableView {
        Label("Choose a Demo", systemImage: "sparkles")
      }
      .navigationTitle("Textual")
    }
  }
}

#Preview {
  DemoSplitView()
}
