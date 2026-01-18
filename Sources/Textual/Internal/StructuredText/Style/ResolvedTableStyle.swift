import SwiftUI

// NB: Enables environment resolution in `TableStyle` and its background / overlay hooks.

extension StructuredText {
  struct ResolvedTableStyle<S: TableStyle>: View {
    private let style: S
    private let configuration: S.Configuration

    init(_ style: S, configuration: S.Configuration) {
      self.style = style
      self.configuration = configuration
    }

    var body: S.Body {
      style.makeBody(configuration: configuration)
    }
  }

  struct ResolvedTableBackground<S: TableStyle>: View {
    private let style: S
    private let layout: TableLayout

    init(_ style: S, layout: TableLayout) {
      self.style = style
      self.layout = layout
    }

    var body: S.Background {
      style.makeBackground(layout: layout)
    }
  }

  struct ResolvedTableOverlay<S: TableStyle>: View {
    private let style: S
    private let layout: TableLayout

    init(_ style: S, layout: TableLayout) {
      self.style = style
      self.layout = layout
    }

    var body: S.Overlay {
      style.makeOverlay(layout: layout)
    }
  }
}

extension StructuredText.TableStyle {
  @MainActor func resolve(configuration: Configuration) -> some View {
    StructuredText.ResolvedTableStyle(self, configuration: configuration)
  }

  @MainActor func resolveBackground(layout: StructuredText.TableLayout) -> some View {
    StructuredText.ResolvedTableBackground(self, layout: layout)
  }

  @MainActor func resolveOverlay(layout: StructuredText.TableLayout) -> some View {
    StructuredText.ResolvedTableOverlay(self, layout: layout)
  }
}
