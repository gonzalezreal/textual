import SwiftUI

/// Configures the text reveal animation applied while content is streaming.
///
/// Use `RevealAnimation` together with ``TextualNamespace/textStreaming(_:)`` to fade in newly
/// arrived text — for example, Markdown streamed incrementally from a language model — in small
/// glyph clusters, similar to the reveal effect in ChatGPT/Claude's iOS apps.
///
/// ```swift
/// StructuredText(markdown: streamedMarkdown)
///   .textual.textStreaming(isStillStreaming)
///   .textual.revealAnimation(.default)
/// ```
///
/// The reveal is a smoothing/pacing layer, not a gate: it can make bursty delivery feel like a
/// comfortable, constant-pace typing effect, but it never lets the visible text lag more than
/// ``maxBacklogDuration`` behind what has actually arrived, and it fast-finishes any remaining
/// backlog within ``streamEndCatchUpDuration`` the moment streaming ends — so the animation never
/// makes the complete response take meaningfully longer to appear than the underlying data itself
/// took to arrive.
public struct RevealAnimation: Sendable, Hashable {
  /// The nominal reveal rate, in glyphs per second, while backlog is within budget.
  public var glyphsPerSecond: Double

  /// The width of the fade window, in glyphs. A cluster of roughly this many glyphs is mid-fade
  /// at any instant. Intended range is 4...8, matching a subtle, non-per-letter reveal.
  public var clusterSize: Int

  /// The width of the opacity/blur fade ramp, in glyphs. Wider values keep more text — spanning
  /// several words or lines — simultaneously mid-fade, reading as a broad, flowing wave rather
  /// than a narrow moving band. `clusterSize` still governs the granularity of that gradient, so
  /// widening this alone doesn't make the reveal chunkier, just longer.
  public var fadeWindow: Double

  /// The blur radius applied to glyphs while they're mid-fade. Tapers to zero as a cluster
  /// settles.
  public var blurRadius: CGFloat

  /// The animation applied to a block's height as it grows to accommodate newly-streamed lines.
  /// Set to `nil` to disable this companion animation and let height changes snap instantly.
  public var heightAnimation: Animation?

  /// The maximum amount of backlog, expressed as a duration at ``glyphsPerSecond``, the reveal
  /// may accumulate before it speeds up to catch back up.
  public var maxBacklogDuration: TimeInterval

  /// How quickly any remaining backlog resolves once streaming ends, overriding the normal pace.
  public var streamEndCatchUpDuration: TimeInterval

  /// Whether the reveal animation is active. When `false`, content streams in at full opacity
  /// immediately, with no reveal renderer attached.
  public var isEnabled: Bool

  /// Creates a reveal animation configuration.
  public init(
    glyphsPerSecond: Double = 45,
    clusterSize: Int = 6,
    fadeWindow: Double = 80,
    blurRadius: CGFloat = 1,
    heightAnimation: Animation? = .easeOut(duration: 0.25),
    maxBacklogDuration: TimeInterval = 0.6,
    streamEndCatchUpDuration: TimeInterval = 0.15,
    isEnabled: Bool = true
  ) {
    self.glyphsPerSecond = glyphsPerSecond
    self.clusterSize = clusterSize
    self.fadeWindow = fadeWindow
    self.blurRadius = blurRadius
    self.heightAnimation = heightAnimation
    self.maxBacklogDuration = maxBacklogDuration
    self.streamEndCatchUpDuration = streamEndCatchUpDuration
    self.isEnabled = isEnabled
  }

  /// The default reveal animation.
  public static let `default` = RevealAnimation()

  /// A disabled reveal animation. Equivalent to not enabling ``TextualNamespace/textStreaming(_:)``.
  public static let disabled = RevealAnimation(isEnabled: false)
}

extension EnvironmentValues {
  @usableFromInline @Entry var revealAnimation: RevealAnimation = .default

  /// Whether the content behind this part of the view hierarchy may still be growing (e.g.
  /// streamed from a language model). `BlockContent` and the list views narrow this to `false`
  /// for every block/item except the last one, so only the actively-growing leaf ever animates.
  @usableFromInline @Entry var textStreamingEnabled: Bool = false
}
