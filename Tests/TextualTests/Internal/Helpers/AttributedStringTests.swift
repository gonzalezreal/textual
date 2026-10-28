import SwiftUI
import Testing

@testable import Textual

struct AttributedStringTests {
  @Test func slugified() {
    #expect(AttributedString("Hello World").slugified() == "hello-world")
    #expect(AttributedString("What's this?").slugified() == "whats-this")
    #expect(AttributedString("Hello  World").slugified() == "hello-world")
    #expect(AttributedString("A - B - C").slugified() == "a-b-c")
    #expect(AttributedString("Hello\tWorld").slugified() == "hello-world")
    #expect(AttributedString("Hello\nWorld").slugified() == "hello-world")
    #expect(AttributedString("---Hello---").slugified() == "hello")
    #expect(AttributedString("123 Test").slugified() == "123-test")
    #expect(AttributedString("").slugified() == "")
  }

  @Test func replacingSoftBreaks() throws {
    let markdown = try AttributedString(markdown: "Soft\n**break** and hard  \nbreak")

    let lineBreak = markdown.replacingSoftBreaks(with: .lineBreak)
    let breaks = lineBreak.runs.filter { lineBreak[$0.range].characters.contains("\n") }

    #expect(markdown.replacingSoftBreaks(with: .space) == markdown)
    #expect(String(lineBreak.characters) == "Soft\nbreak and hard\nbreak")
    #expect(breaks.map { $0.inlinePresentationIntent } == [.lineBreak, .lineBreak])
  }
}
