import SwiftUI

// MARK: - Overview
//
// BlockVStack arranges blocks vertically with CSS-style margin collapsing behavior. Adjacent
// blocks' top and bottom spacing collapses by taking the maximum value rather than summing,
// matching how CSS margins work.
//
// List items can override block spacing with environment-driven list item spacing for consistent
// spacing within lists regardless of individual block preferences.

extension StructuredText {
  struct BlockVStack<Content: View>: View {
    @Environment(\.multilineTextAlignment) private var textAlignment

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    var body: some View {
      Group(subviews: content) { children in
        BlockVStackLayout(textAlignment: textAlignment) {
          ForEach(children) {
            BlockLayoutView($0)
          }
        }
      }
    }
  }
}

extension StructuredText {
  fileprivate struct BlockLayoutView<Content: View>: View {
    @Environment(\.listItemSpacingEnabled) private var listItemSpacingEnabled
    @Environment(\.resolvedListItemSpacing) private var resolvedListItemSpacing

    @State private var blockSpacing = BlockSpacing()

    private let content: Content

    init(_ content: Content) {
      self.content = content
    }

    var body: some View {
      // Read the block spacing preference and apply it as a layout value
      content
        .onPreferenceChange(BlockSpacingKey.self) { @MainActor value in
          // Override with the resolved list item spacing if enabled
          blockSpacing = listItemSpacingEnabled ? resolvedListItemSpacing : value
        }
        .layoutValue(key: BlockSpacingKey.self, value: blockSpacing)
    }
  }

  fileprivate struct BlockVStackLayout: Layout {
    struct Cache {
      let spacings: [CGFloat]
    }

    let textAlignment: TextAlignment

    func makeCache(subviews: Subviews) -> Cache {
      return Cache(
        spacings: subviews.indices.dropLast().map { index in
          let current = subviews[index]
          let next = subviews[index + 1]
          let currentBottom = current[BlockSpacingKey.self].bottom
          let nextTop = next[BlockSpacingKey.self].top

          // Take the maximum block spacing, otherwise the preferred view spacing
          return [currentBottom, nextTop].compactMap(\.self).max()
            ?? current.spacing.distance(to: next.spacing, along: .vertical)
        }
      )
    }

    func sizeThatFits(
      proposal: ProposedViewSize,
      subviews: Subviews, cache: inout Cache
    ) -> CGSize {
      if let width = proposal.width, width <= 0 {
        return .zero
      }

      var size = CGSize.zero

      for view in subviews {
        let viewSize = view.sizeThatFits(.init(width: proposal.width, height: nil))
        size.height += viewSize.height
        size.width = max(size.width, viewSize.width)
      }

      size.height += cache.spacings.reduce(0, +)

      return size
    }

    func placeSubviews(
      in bounds: CGRect,
      proposal: ProposedViewSize,
      subviews: Subviews, cache: inout Cache
    ) {
      var currentY: CGFloat = 0

      for (index, view) in zip(subviews.indices, subviews) {
        let viewProposal = ProposedViewSize(width: proposal.width, height: nil)
        let viewSize = view.sizeThatFits(viewProposal)

        var point = bounds.origin

        switch textAlignment {
        case .leading:
          break  // do nothing
        case .center:
          point.x += (bounds.width - viewSize.width) / 2
        case .trailing:
          point.x += bounds.width - viewSize.width
        }

        point.y += currentY

        view.place(at: point, proposal: viewProposal)

        currentY += viewSize.height

        if index < subviews.count - 1 {
          currentY += cache.spacings[index]
        }
      }
    }
  }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
#Preview {
  @Previewable @State var textAlignment = TextAlignment.leading
  @Previewable @State var blockSpacing: CGFloat = 1

  VStack {
    GroupBox {
      Picker("Text Alignment", selection: $textAlignment) {
        Text("Leading").tag(TextAlignment.leading)
        Text("Center").tag(TextAlignment.center)
        Text("Trailing").tag(TextAlignment.trailing)
      }
      .pickerStyle(.segmented)
      HStack {
        Text("2nd / 3rd Spacing")
        Slider(value: $blockSpacing, in: 0...3)
      }
    }
    Spacer()
    StructuredText.BlockVStack {
      Text(
        """
        Listen to your sister, Morty. To live is to risk it all, otherwise you’re just an inert \
        chunk of randomly assembled molecules drifting wherever the universe blows you.
        """
      )
      .textual.blockSpacing(.fontScaled(bottom: 1))
      Text(
        """
        Listen, Morty, I hate to break it to you but what people call "love" is just a chemical \
        reaction that compels animals to breed. It hits hard, Morty, then it slowly fades, \
        leaving you stranded in a failing marriage. I did it. Your parents are gonna do it. \
        Break the cycle, Morty. Rise above. Focus on science.
        """
      )
      .textual.blockSpacing(.fontScaled(bottom: blockSpacing))
      Text(
        """
        Wow, I really Cronenberged up the whole place, huh Morty? Just a bunch a Cronenbergs \
        walkin' around.
        """
      )
      .textual.blockSpacing(.fontScaled(top: 1, bottom: 1))
    }
    .border(Color.red)
    Spacer()
  }
  .multilineTextAlignment(textAlignment)
  .padding()
}
