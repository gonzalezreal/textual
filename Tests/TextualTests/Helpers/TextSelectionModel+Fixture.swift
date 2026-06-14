#if TEXTUAL_ENABLE_TEXT_SELECTION
  import SnapshotTesting
  import SwiftUI

  @testable import Textual

  extension TextSelectionModel {
    convenience init(fixtureName name: String) throws {
      let url = Bundle.module.url(
        forResource: "Fixtures/TextSelectionModel/\(name)",
        withExtension: "json"
      )
      let data = try url.map { try Data(contentsOf: $0) } ?? Data()
      let layoutCollection = try JSONDecoder().decode(CodableTextLayoutCollection.self, from: data)

      self.init(layoutCollection: layoutCollection)
    }
  }

  #if os(iOS) && !targetEnvironment(macCatalyst)
    extension TextSelectionModel {
      @MainActor static func recordFixture<Content: View>(
        for content: Content,
        named name: String,
        config: ViewImageConfig = .iPhoneSe
      ) throws {
        let snapshot =
          Snapshotting
          .textLayoutCollection(config: config)
          .snapshot(content)

        snapshot.run { output in
          let data = Data(output.utf8)
          let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/TextSelectionModel/\(name).json")
          let directoryURL = url.deletingLastPathComponent()
          do {
            try FileManager.default.createDirectory(
              at: directoryURL,
              withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
          } catch {
            fatalError("Failed to write data to \(url.path): \(error)")
          }
        }
      }
    }
  #endif
#endif
