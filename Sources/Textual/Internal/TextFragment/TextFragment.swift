import SwiftUI

// MARK: - Overview
//
// TextFragment renders attributed content as SwiftUI.Text with support for inline
// attachments, links, and selection. It uses a TextBuilder to construct and cache
// Text values, minimizing rebuilds during resize by keying on attachment sizes.
//
// Attachments are represented as placeholder images tagged with AttachmentAttribute. The
// actual attachment views are rendered in an overlay using the resolved Text.Layout
// geometry. Three modifiers are applied at the fragment level:
//
// - TextSelectionBackground renders selection highlights on macOS
// - AttachmentOverlay draws attachments at their run locations with selection-aware dimming
// - TextLinkInteraction handles tap gestures on links
//
// These overlays use backgroundPreferenceValue and overlayPreferenceValue to access
// Text.Layout and render in fragment-local coordinates. Fragment-level overlays enable
// coordinate space isolation and keep scrollable regions interactive.
//
// An ancestor view must define a named coordinate space (.textContainer) for the text
// container. TextFragment uses onGeometryChange to observe the container size and rebuild
// Text when attachment sizes need to change.
//
// TextFragment is used by InlineText and StructuredText (via BlockContent) to render
// attributed content with inline attachments, links, and selection.
//
// ## Reveal animation
//
// While `\.textStreamingEnabled` is true (see RevealAnimation.swift), newly-arrived content
// fades in via RevealTextRenderer instead of appearing immediately. `RevealState` tracks how
// far the reveal has progressed as a checkpoint (a glyph count, the date it was set, and the
// rate to advance from it); `currentGlyphCount(at:)` is a pure function of elapsed time, so a
// TimelineView only needs to mount while there's backlog left to drain — it unmounts the
// instant the reveal catches up, at which point ticking stops entirely.
//
// Selection is suppressed on an actively-revealing fragment by clearing its own contribution
// to the `Text.LayoutKey` preference (the same technique Overflow.swift uses to keep
// horizontally-scrolled regions out of an ancestor's selection collection) — an ancestor
// TextSelectionInteraction aggregates Text.LayoutKey from every descendant Text, so a fragment
// that clears its own entry is simply invisible to that collection while it's mid-fade, while
// every other, already-settled fragment remains selectable throughout.

struct TextFragment<Content: AttributedStringProtocol>: View {
  @Environment(\.textEnvironment) private var textEnvironment
  @Environment(\.textStreamingEnabled) private var textStreamingEnabled
  @Environment(\.revealAnimation) private var revealAnimation
  @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

  @State private var textBuilder: TextBuilder?
  @State private var revealState = RevealState()
  @State private var hasSeenInitialContent = false

  private let content: Content

  init(_ content: Content) {
    self.content = content
  }

  var body: some View {
    renderedText
      .onGeometryChange(for: CGSize?.self, of: \.textContainerSize) { size in
        guard let size, let textBuilder else { return }
        textBuilder.sizeChanged(size, environment: textEnvironment)
      }
      .onChange(of: content, initial: true) { oldValue, newValue in
        self.textBuilder = TextBuilder(newValue, environment: textEnvironment)
        updateRevealState(from: oldValue, to: newValue)
      }
      .onChange(of: shouldReveal) { wasRevealing, isRevealing in
        guard wasRevealing, !isRevealing else { return }
        if textStreamingEnabled {
          // Streaming is still nominally active — reveal turned off for another reason (Reduce
          // Motion, isEnabled == false). Snap instantly; no animated catch-up.
          revealState.snapToFull()
        } else {
          // Streaming actually ended (app finished, or this fragment is no longer the growing
          // one) — fast-finish any remaining backlog rather than continuing at the nominal pace.
          revealState.fastFinish(configuration: revealAnimation, now: Date())
        }
      }
      .modifier(TextSelectionBackground())
      .modifier(AttachmentOverlay(attachments: content.attachments()))
      .modifier(TextLinkInteraction())
      // Clear this fragment's own Text.LayoutKey contribution while it's actively revealing, so
      // an ancestor TextSelectionInteraction's shared selection collection skips it. Applied
      // after the modifiers above, which still need the real, untransformed layout.
      .transformPreference(Text.LayoutKey.self) { value in
        if shouldReveal {
          value = []
        }
      }
  }

  private var shouldReveal: Bool {
    textStreamingEnabled && revealAnimation.isEnabled && !accessibilityReduceMotion
  }

  @ViewBuilder
  private var renderedText: some View {
    if shouldReveal, !revealState.isCaughtUp {
      TimelineView(.animation) { timeline in
        text.textRenderer(
          RevealTextRenderer(
            revealedGlyphCount: revealState.currentGlyphCount(at: timeline.date),
            totalGlyphCount: Double(revealState.targetGlyphCount),
            configuration: revealAnimation
          )
        )
      }
    } else if shouldReveal {
      // Streaming but caught up right now — keep the renderer attached (a new burst may arrive
      // at any moment) without paying for a ticking TimelineView while there's nothing to drain.
      text.textRenderer(
        RevealTextRenderer(
          revealedGlyphCount: Double(revealState.targetGlyphCount),
          totalGlyphCount: Double(revealState.targetGlyphCount),
          configuration: revealAnimation
        )
      )
    } else {
      text
    }
  }

  private var text: Text {
    (textBuilder?.text ?? Text(verbatim: "")).customAttribute(TextFragmentAttribute())
  }

  private func updateRevealState(from oldValue: Content, to newValue: Content) {
    let now = Date()
    let change: RevealDiff.Change

    if hasSeenInitialContent {
      change = RevealDiff.classify(
        previousCharacters: oldValue.characters,
        newCharacters: newValue.characters,
        revealedCount: Int(revealState.currentGlyphCount(at: now))
      )
    } else {
      // SwiftUI's onChange(initial: true) hands us oldValue == newValue on the very first call —
      // treat the initial content as a fresh append from nothing so it reveals from scratch
      // rather than being misclassified as .unchanged (which would leave nothing on screen).
      change = .append(newCount: newValue.characters.count)
      hasSeenInitialContent = true
    }

    revealState.apply(change, configuration: revealAnimation, now: now)

    if !textStreamingEnabled {
      // Not currently streaming — nothing should be mid-fade. Snap immediately so state stays
      // accurate for whenever streaming might turn on later, with no visible effect now (the
      // renderer isn't attached while `shouldReveal` is false regardless).
      revealState.snapToFull()
    }
  }
}

struct TextFragmentAttribute: TextAttribute {
}

extension Text.Layout {
  var isTextFragment: Bool {
    first?.first?[TextFragmentAttribute.self] != nil
  }
}

extension CoordinateSpaceProtocol where Self == NamedCoordinateSpace {
  static var textContainer: NamedCoordinateSpace {
    .named("textContainer")
  }
}

extension GeometryProxy {
  fileprivate var textContainerSize: CGSize? {
    bounds(of: .textContainer)?.size
  }
}
