import SwiftUI
import Testing

@testable import Textual

struct FontProviderTests {
  @Test(
    arguments: [
      Font.system(.body, design: .default, weight: .medium),
      .system(size: 17, weight: .regular, design: .default),
      .custom("Helvetica", size: 17),
      .init(PlatformFont.preferredFont(forTextStyle: .body)),
      .body.bold(),
      .body.bold().italic(),
      .body.bold().italic().monospaced(),
      .body.bold().italic().monospacedDigit(),
      .body.bold().italic().smallCaps(),
      .body.italic().weight(.ultraLight),
      .body.italic().weight(.ultraLight).width(.condensed),
      .body.italic().weight(.ultraLight).width(.condensed).leading(.tight),
    ]
  )
  func roundtrip(font: Font) {
    let resolvedFont = AnyFontProvider(font: font)?.resolve(in: .init())
    #expect(resolvedFont == font)
  }

  @Test func textStyleFontSize() {
    // given
    let font = Font.body.bold().monospaced()
    let fontProvider = AnyFontProvider(font: font)

    let environment = TextEnvironmentValues(dynamicTypeSize: .xxxLarge)

    let expectedSize = FontDescriptor.preferredFontDescriptor(
      withTextStyle: .body,
      in: environment
    ).pointSize

    // when
    let size = fontProvider?.size(in: environment)

    // then
    #expect(size == expectedSize)
  }

  @Test func textStyleFontScale() {
    // given
    let scale = CGFloat(0.8)
    let font = Font.body.bold().monospaced()

    var fontProvider = AnyFontProvider(font: font)
    fontProvider?.scale = scale

    let environment = TextEnvironmentValues(dynamicTypeSize: .xxxLarge)

    let expectedSize =
      FontDescriptor.preferredFontDescriptor(
        withTextStyle: .body,
        in: environment
      ).pointSize * scale

    // when
    let size = fontProvider?.size(in: environment)

    // then
    #expect(size == expectedSize)
  }

  @Test func textStyleFontScaleResolve() {
    // given
    let scale = CGFloat(0.8)
    let font = Font.body.bold().monospaced()

    var fontProvider = AnyFontProvider(font: font)
    fontProvider?.scale = scale

    let environment = TextEnvironmentValues(dynamicTypeSize: .xxxLarge)

    let fontDescriptor = FontDescriptor.preferredFontDescriptor(
      withTextStyle: .body,
      in: environment
    )
    let expectedFont = Font(
      CTFont(
        fontDescriptor,
        size: fontDescriptor.pointSize * scale
      )
    ).bold().monospaced()

    // when
    let resolvedFont = fontProvider?.resolve(in: environment)

    // then
    #expect(resolvedFont == expectedFont)
  }

  @Test func systemFontScaleResolve() {
    // given
    let scale = CGFloat(0.8)
    let font = Font.system(size: 17).bold().monospaced()

    var fontProvider = AnyFontProvider(font: font)
    fontProvider?.scale = scale

    // when
    let size = fontProvider?.size(in: .init())
    let resolvedFont = fontProvider?.resolve(in: .init())

    // then
    #expect(size == 17 * scale)
    #expect(resolvedFont == .system(size: 17 * scale).bold().monospaced())
  }

  #if compiler(>=6.2)
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @Test func textStyleScaledByResolve() {
      // given
      let font = Font.body
        .scaled(by: 2)
        .bold()
        .monospaced()
        .scaled(by: 3)
      let fontProvider = AnyFontProvider(font: font)
      let environment = TextEnvironmentValues(dynamicTypeSize: .xxxLarge)

      let fontDescriptor = FontDescriptor.preferredFontDescriptor(
        withTextStyle: .body,
        in: environment
      )

      // when
      let size = fontProvider?.size(in: environment)
      let resolvedFont = fontProvider?.resolve(in: environment)

      // then
      #expect(size == fontDescriptor.pointSize * 2 * 3)
      #expect(resolvedFont == font)
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, watchOS 26.0, visionOS 26.0, *)
    @Test func systemFontScaledByResolve() {
      // given
      let scale = CGFloat(0.8)
      let font = Font.system(size: 17)
        .bold()
        .scaled(by: scale)
        .monospaced()

      let fontProvider = AnyFontProvider(font: font)

      // when
      let size = fontProvider?.size(in: .init())
      let resolvedFont = fontProvider?.resolve(in: .init())

      // then
      #expect(size == 17 * scale)
      #expect(resolvedFont == font)
    }
  #endif

  #if canImport(UIKit)
    @Test func customFontRelativeToTextStyleScale() {
      // given
      let scale = CGFloat(0.8)
      let font = Font.custom("Helvetica", size: 17).bold()

      var fontProvider = AnyFontProvider(font: font)
      fontProvider?.scale = scale

      let environment = TextEnvironmentValues(dynamicTypeSize: .xxxLarge)

      let expectedSize =
        PlatformFont.custom(
          "Helvetica",
          size: 17,
          relativeTo: .body,
          in: environment
        ).pointSize * scale

      // when
      let size = fontProvider?.size(in: environment)

      // then
      #expect(size == expectedSize)
    }
  #endif

  @Test func customFontScaleResolve() {
    // given
    let scale = CGFloat(0.8)
    let font = Font.custom("Helvetica", size: 17, relativeTo: .callout).bold()

    var fontProvider = AnyFontProvider(font: font)
    fontProvider?.scale = scale

    let expectedFont = Font.custom("Helvetica", size: 17 * scale, relativeTo: .callout).bold()

    // when
    let resolvedFont = fontProvider?.resolve(in: .init())

    // then
    #expect(resolvedFont == expectedFont)
  }

  @Test func customFontFixedSizeScaleResolve() {
    // given
    let scale = CGFloat(0.8)
    let font = Font.custom("Helvetica", fixedSize: 17).bold()

    var fontProvider = AnyFontProvider(font: font)
    fontProvider?.scale = scale

    let expectedFont = Font.custom("Helvetica", fixedSize: 17 * scale).bold()

    // when
    let resolvedFont = fontProvider?.resolve(in: .init())

    // then
    #expect(resolvedFont == expectedFont)
  }

  @Test func platformFontScaleResolve() {
    // given
    let scale = CGFloat(0.8)
    let font = Font(PlatformFont.systemFont(ofSize: 17)).bold()

    var fontProvider = AnyFontProvider(font: font)
    fontProvider?.scale = scale

    let expectedFont = Font(PlatformFont.systemFont(ofSize: 17 * scale)).bold()

    // when
    let size = fontProvider?.size(in: .init())
    let resolvedFont = fontProvider?.resolve(in: .init())

    // then
    #expect(size == 17 * 0.8)
    #expect(resolvedFont == expectedFont)
  }
}
