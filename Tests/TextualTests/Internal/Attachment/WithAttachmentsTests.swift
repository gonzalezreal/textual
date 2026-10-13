import SwiftUI
import Testing

@testable import Textual

struct WithAttachmentsTests {
  private static let attachmentImage = Textual.Image(
    data: Data(
      base64Encoded:
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    )!
  )!

  private static func makeAttachment(text: String) -> ImageAttachment {
    ImageAttachment(image: attachmentImage, text: text)
  }

  /// Suspends `attachment(for:...)` until `open()` is called, ignoring cancellation like a
  /// network request that is already in flight.
  private struct GatedLoader: AttachmentLoader {
    let gate: Gate

    func attachment(
      for _: URL,
      text: String,
      environment _: ColorEnvironmentValues
    ) async throws -> ImageAttachment {
      await gate.wait()
      return makeAttachment(text: text)
    }
  }

  private struct ImmediateLoader: AttachmentLoader {
    func attachment(
      for _: URL,
      text: String,
      environment _: ColorEnvironmentValues
    ) async throws -> ImageAttachment {
      makeAttachment(text: text)
    }
  }

  private actor Gate {
    private var opened = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    var hasWaiters: Bool {
      !continuations.isEmpty
    }

    func wait() async {
      if opened { return }
      await withCheckedContinuation { continuation in
        continuations.append(continuation)
      }
    }

    func open() {
      opened = true
      continuations.forEach { $0.resume() }
      continuations.removeAll()
    }
  }

  private func imageURLString(_ text: String, url: URL) -> AttributedString {
    var attributedString = AttributedString(text)
    attributedString.imageURL = url
    return attributedString
  }

  @Test("Resolving a string without attachment URLs clears stale resolved attachments")
  @MainActor func clearsResolvedAttachmentsWhenStringHasNoAttachmentURLs() async {
    let model = WithAttachments<EmptyView>.Model()
    let environment = ColorEnvironmentValues(colorScheme: .light, colorSchemeContrast: .standard)
    let withImageURL = imageURLString(
      "image", url: URL(string: "https://example.com/image.png")!

    )

    await model.resolveAttachments(
      in: withImageURL,
      imageAttachmentLoader: ImmediateLoader(),
      emojiAttachmentLoader: ImmediateLoader(),
      environment: environment
    )
    #expect(model.resolvedAttributedString?.containsValues(for: [\.textual.attachment]) == true)

    await model.resolveAttachments(
      in: AttributedString("plain"),
      imageAttachmentLoader: ImmediateLoader(),
      emojiAttachmentLoader: ImmediateLoader(),
      environment: environment
    )
    #expect(model.resolvedAttributedString == nil)
  }

  @Test("A cancelled resolution discards its stale results")
  @MainActor func cancelledResolutionDiscardsStaleResults() async throws {
    let model = WithAttachments<EmptyView>.Model()
    let gate = Gate()
    let environment = ColorEnvironmentValues(colorScheme: .light, colorSchemeContrast: .standard)
    let staleString = imageURLString(
      "stale", url: URL(string: "https://example.com/stale.png")!
    )
    let freshString = imageURLString(
      "fresh", url: URL(string: "https://example.com/fresh.png")!
    )

    let staleTask = Task {
      await model.resolveAttachments(
        in: staleString,
        imageAttachmentLoader: GatedLoader(gate: gate),
        emojiAttachmentLoader: ImmediateLoader(),
        environment: environment
      )
    }

    while await !gate.hasWaiters {
      try await Task.sleep(nanoseconds: 1_000_000)
    }

    staleTask.cancel()

    await model.resolveAttachments(
      in: freshString,
      imageAttachmentLoader: ImmediateLoader(),
      emojiAttachmentLoader: ImmediateLoader(),
      environment: environment
    )
    #expect(model.resolvedAttributedString.map { String($0.characters) } == "fresh")

    await gate.open()
    await staleTask.value
    #expect(model.resolvedAttributedString.map { String($0.characters) } == "fresh")
  }
}
