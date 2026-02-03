# Add Interactive Attachment Rendering Mode

## Summary

Adds an opt-in `.interactive` rendering mode for inline attachments, enabling fully interactive SwiftUI views (buttons, gestures, state updates) while preserving the existing performant Canvas-based rendering as the default.

## Motivation

The current Canvas-based rendering converts attachment views into static symbols, which is performant but prevents interactivity. Use cases requiring tappable inline elements (citation pills, tag chips, inline buttons) currently cannot be implemented.

### Real-World Use Case

Medical documentation app with AI-generated clinical notes containing inline citation references:

```swift
"First-line: Amoxicillin 15mg/kg [PubMed] [NICE Guidelines]"
                                    ^         ^
                              Tappable pills showing citation details
```

Without interactivity, users cannot tap citations to view sources inline with the text.

## Changes

### 1. New Public API

**`AttachmentRenderingMode.swift`** (NEW)

```swift
public enum AttachmentRenderingMode {
  case canvas      // Default - performant, static
  case interactive // Opt-in - interactive, slight performance cost
}

extension View {
  public func attachmentRenderingMode(_ mode: AttachmentRenderingMode) -> some View
}
```

**Usage:**

```swift
// Default behavior (unchanged)
InlineText(markdown: text)

// Opt into interactive attachments
InlineText(markdown: text)
  .attachmentRenderingMode(.interactive)
```

### 2. Updated Implementation

**`AttachmentView.swift`** (MODIFIED)

- Preserved original Canvas rendering (default)
- Added new ZStack-based interactive rendering
- Switched via environment value
- Shared opacity/selection logic between both modes

**Architecture:**

```swift
var body: some View {
  switch renderingMode {
  case .canvas:
    canvasRendering      // Original implementation
  case .interactive:
    interactiveRendering // New implementation
  }
}
```

### 3. Demo Implementation

**`PillAttachment.swift`** (NEW - Example)

Demonstrates interactive pill attachments with:
- Tappable buttons
- Custom styling
- Proper sizing and baseline alignment

**`InlineTextDemo.swift`** (UPDATED)

Added "Interactive Pill Attachments" section showing tappable citation pills inline with text.

## Backward Compatibility

✅ **100% backward compatible**

- Default behavior unchanged (`.canvas` mode)
- Existing code requires no modifications
- Opt-in via explicit API call
- No breaking changes to public API

## Performance Considerations

### Canvas Mode (Default)
- Views resolved once as symbols
- Efficient redrawing via Canvas
- **Best for**: Static content (images, emoji, non-interactive elements)

### Interactive Mode (Opt-in)
- Views positioned directly in ZStack
- Full SwiftUI view lifecycle
- Slight overhead from additional view hierarchy
- **Best for**: Interactive content (buttons, tappable chips, dynamic state)

**Recommendation:** Only use `.interactive` when interactivity is required.

## Testing

Tested with:
- ✅ Static emoji (Canvas mode - default)
- ✅ Interactive pill buttons (.interactive mode)
- ✅ Text wrapping across multiple lines
- ✅ Text selection (both modes)
- ✅ Accessibility (VoiceOver support in interactive mode)
- ✅ Dynamic Type
- ✅ Multiple attachments inline

## Example: Interactive Citation Pills

```swift
// Custom attachment
struct CitationPill: Attachment {
  let citationId: Int
  let title: String

  var body: some View {
    Button(action: { showCitation(citationId) }) {
      HStack(spacing: 4) {
        Text("📎")
        Text(title)
          .font(.system(size: 12, weight: .medium))
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color.secondary.opacity(0.2))
      .cornerRadius(8)
    }
  }

  // ... sizing and conformance
}

// Usage in markdown parser
var text = AttributedString("See ")
var pill = AttributedString("PubMed Study")
pill.textual.attachment = AnyAttachment(
  CitationPill(citationId: 123, title: "PubMed")
)
text.append(pill)
text.append(AttributedString(" for details."))

// Render with interactivity
InlineText(text)
  .attachmentRenderingMode(.interactive)
```

**Result:** Tappable "PubMed Study" pill inline with text that opens citation details.

## API Design Rationale

### Why Environment Value?

1. **Cascading:** Set once at top level, applies to all nested `InlineText` views
2. **SwiftUI Convention:** Matches patterns like `.colorScheme()`, `.font()`
3. **Flexibility:** Can be overridden at any level of the view hierarchy

### Why Default to Canvas?

1. **Backward Compatibility:** Existing apps see no behavior change
2. **Performance:** Most use cases (images, emoji) don't need interactivity
3. **Opt-in Complexity:** Interactive mode adds view hierarchy overhead

### Alternative Considered: Per-Attachment Flag

```swift
// ❌ Not chosen - more complex API
struct MyAttachment: Attachment {
  var requiresInteractivity: Bool { true }
}
```

**Rejected because:**
- Mixes rendering concern with attachment definition
- Complicates implementation (mixed Canvas + ZStack)
- Less control for developers

## Documentation

All new APIs include:
- DocC-style documentation comments
- Usage examples
- Performance considerations
- Clear default behavior

## Migration Guide

**No migration needed!**

Existing code continues working unchanged. To enable interactivity:

```swift
// Before (works unchanged)
InlineText(markdown: text)

// After (opt into interactivity)
InlineText(markdown: text)
  .attachmentRenderingMode(.interactive)
```

## Open Questions

1. **Naming:** Is `attachmentRenderingMode` clear enough? Alternatives:
   - `.interactiveAttachments(true/false)`
   - `.attachmentInteractivity(.enabled)`

2. **Performance:** Should we document specific performance characteristics?

3. **Future:** Could we auto-detect interactivity needs (e.g., attachments with gestures)?

## Checklist

- [x] Implementation preserves original behavior
- [x] New API is public and documented
- [x] Demo showcases interactive attachments
- [x] Backward compatible (no breaking changes)
- [x] Performance considerations documented
- [x] Code follows existing style conventions
- [x] Works with text selection
- [x] Accessibility support maintained

## Files Changed

```
Sources/Textual/AttachmentRenderingMode.swift                          (NEW)
Sources/Textual/Internal/Attachment/AttachmentView.swift               (MODIFIED)
Examples/TextualDemo/TextualDemo/PillAttachment.swift                  (NEW - Demo)
Examples/TextualDemo/TextualDemo/InlineTextDemo.swift                  (UPDATED - Demo)
```

## Git Diff Stats

```
4 files changed, 185 insertions(+), 27 deletions(-)
```

---

## Request for Feedback

This PR adds a capability that unlocks new use cases (interactive inline elements) while maintaining full backward compatibility. Feedback welcome on:

1. API naming and design
2. Performance characteristics
3. Documentation clarity
4. Additional test cases needed
