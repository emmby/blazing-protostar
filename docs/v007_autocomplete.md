# Blazing Protostar Autocomplete Prerequisites Specification

## Overview

This document specifies the features needed in the `blazing_protostar` library to support autocomplete functionality in Resonant Bohr. The autocomplete feature will be implemented in Resonant Bohr, but it requires certain rendering and interaction capabilities from the markdown editor library.

## Executive Summary

**Goal**: Enable inline autocomplete functionality for directives, images, and other markdown syntax in Blazing Protostar-based editors.

**Approach**: Three-phased implementation with incremental delivery:
- **Phase 1**: Ghost text rendering (inline TextSpan approach)
- **Phase 2**: Key event handlers for suggestion acceptance
- **Phase 3**: Text manipulation helpers (optional enhancement)

**Key Decisions**:
- Ghost text rendered as inline `TextSpan` (not absolute positioning) for better reliability
- Theme-based color styling (opacity 0.4) for consistency
- Single-line ghost text only for MVP (multi-line deferred)
- Consumer (Resonant Bohr) manages ghost text lifecycle (no automatic clearing)
- Input sanitization (newlines/tabs → spaces, control chars stripped)
- Phased rollout with example app + widget tests for each phase

**Timeline**: Sequential implementation (Phase 1 → 2 → 3), no specific deadlines.

---

## Required Features

### 1. Ghost Text Overlay API

**Purpose**: Display inline autocomplete suggestions as greyed-out text after the cursor position.

**Requirements**:
- Render text overlay at the current cursor position
- Text should appear in a lighter/greyed color to distinguish it from actual content
- Ghost text should not be part of the actual document content
- Ghost text should update dynamically as the user types
- Ghost text should be dismissible
- **MVP Scope**: Single-line ghost text only (multi-line support deferred to future iteration)

**Proposed API**:

```dart
class MarkdownTextEditingController extends TextEditingController {
  // ... existing properties ...
  
  /// Ghost text to display at cursor position
  /// Set to null or empty string to hide
  String? ghostText;
  
  /// Set ghost text (simplified API)
  /// Input will be automatically sanitized (newlines/tabs replaced with spaces)
  void setGhostText(String? text) {
    ghostText = text;
    notifyListeners();
  }
  
  /// Clear ghost text
  void clearGhostText() {
    ghostText = null;
    notifyListeners();
  }
}
```

**Color Scheme**: Ghost text color is derived from theme automatically (e.g., `Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)`) for consistency.

**Ghost Text Lifecycle**:
Ghost text should automatically clear/dismiss when:
- User moves cursor with arrow keys
- User clicks/taps to a different cursor position
- User types a character that doesn't match the suggestion
- Text field loses focus

Ghost text should update (progressive reveal) when:
- User types a character that matches the next character in the suggestion
- Example: suggestion is `youtube[id]`, user types `y` → ghost text updates to `outube[id]`

**Responsibility**: The consuming application (Resonant Bohr) is responsible for managing the ghost text lifecycle by listening to text/cursor changes and calling `setGhostText()` or `clearGhostText()` as appropriate. Blazing Protostar provides the rendering mechanism but no automatic clearing logic.

**Sanitization**: Ghost text should be sanitized before rendering to handle special characters defensively:
- Newlines (`\n`) and tabs (`\t`) should be replaced with spaces
- Control characters should be stripped or replaced
- Unicode and emoji are allowed and rendered as-is

**Rendering**: The `MarkdownEditor` widget needs to render the ghost text overlay:
- Position: Immediately after cursor
- Style: Semi-transparent grey color
- Layer: Above the text field but not selectable
- Should not interfere with text selection or editing

---

### 2. Custom Key Event Handlers

**Purpose**: Allow Resonant Bohr to intercept specific key events (Tab, Enter) to handle autocomplete acceptance.

**Requirements**:
- Intercept Tab and Enter keys before default handling
- Allow client code to prevent default behavior
- Provide context about current cursor position and selection

**Proposed API**:

```dart
/// Callback for custom key event handling
/// Return true to prevent default behavior, false to allow it
typedef KeyEventHandler = bool Function(KeyEvent event);

class MarkdownEditor extends StatefulWidget {
  // ... existing properties ...
  
  /// Optional custom key event handler
  /// Called before default key handling
  /// Return true to prevent default behavior
  final KeyEventHandler? onKeyEvent;
  
  const MarkdownEditor({
    required this.controller,
    this.readOnly = false,
    this.toolbarBuilder,
    this.onKeyEvent,  // NEW
    // ... other params
  });
}
```

**Usage Example** (in Resonant Bohr):
```dart
MarkdownEditor(
  controller: _controller,
  onKeyEvent: (event) {
    // Check if we have autocomplete suggestion
    if (_currentSuggestion != null) {
      // Accept on Tab or Enter
      if (event.logicalKey == LogicalKeyboardKey.tab ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        _acceptSuggestion();
        return true; // Prevent default
      }
      // Dismiss on Escape
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _dismissSuggestion();
        return true;
      }
    }
    return false; // Allow default handling
  },
)
```

---

### 3. Text Manipulation Helpers (Enhancement)

**Purpose**: Make it easier to replace text at cursor position when accepting autocomplete suggestions.

**Current State**: We already have `insertAtCursor()` which is good.

**Enhancement Request**: Add a method to replace text range:

```dart
class MarkdownTextEditingController extends TextEditingController {
  // ... existing methods ...
  
  /// Replace text in the given range
  void replaceRange(int start, int end, String replacement) {
    final newText = text.substring(0, start) + 
                    replacement + 
                    text.substring(end);
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + replacement.length,
      ),
    );
  }
}
```

This would be helpful for replacing partial text when accepting suggestions.

---

## Implementation Notes for Blazing Protostar Maintainer

### Ghost Text Rendering Implementation

**Approach**: Use `TextSpan` composition in `buildTextSpan()` method rather than absolute positioning.

The ghost text will be rendered inline as part of the text layout by appending a `TextSpan` at the cursor position:

```dart
@override
TextSpan buildTextSpan({
  required BuildContext context,
  TextStyle? style,
  required bool withComposing,
}) {
  // ... existing rendering logic ...
  
  // If ghost text is present, insert it at cursor position
  if (ghostText != null && ghostText!.isNotEmpty) {
    final cursorOffset = selection.baseOffset;
    // Split the rendered spans at cursor position and insert ghost text
    // with semi-transparent theme-based color styling
    final baseColor = style?.color ?? DefaultTextStyle.of(context).style.color;
    final ghostStyle = (style ?? const TextStyle()).copyWith(
      color: (baseColor ?? Colors.black).withOpacity(0.4),
    );
    // Insert TextSpan(text: ghostText, style: ghostStyle) at cursor
  }
  
  return TextSpan(children: renderedSpans);
}
```

**Note**: The exact mechanism for injecting the ghost text TextSpan at the cursor position (post-processing vs. inline during rendering) is an implementation detail to be determined during development.

**Benefits**:
- Automatic positioning with text flow
- Handles scrolling, wrapping, and font metrics automatically
- Simpler implementation than absolute positioning
- No need to calculate screen coordinates

**Rendering Behavior**:
- Ghost text should always render in **raw mode** (plain text, no markdown rendering)
- Ghost text should **never inherit formatting** from surrounding text (always plain grey)
- Since WYSIWYG is disabled at cursor position during editing, ghost text matches this behavior
- Directives and other markdown syntax in ghost text appear as literal text (e.g., `:youtube[id]` shows as-is)
```

### Key Event Handler Implementation

Use Flutter's `Focus` widget to capture key events:

```dart
Focus(
  onKeyEvent: (node, event) {
    if (widget.onKeyEvent != null) {
      final handled = widget.onKeyEvent!(event);
      if (handled) {
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: TextField(...),
)
```

**Key Event Behavior**:
- **Tab key**: When ghost text is showing, accept suggestion. When no ghost text, allow default behavior (insert tab)
- **Enter key**: When ghost text is showing:
  - Plain Enter: Accept suggestion (prevent newline)
  - Shift+Enter: Insert newline (ignore suggestion)
- **Escape key**: Dismiss ghost text if showing
- **Priority**: `onKeyEvent` callback fires and can prevent default behavior by returning `true`

---

## Edge Cases & Considerations

**Empty Document**: Ghost text should work identically in empty documents (cursor at position 0) as in documents with content.

**Long Ghost Text**: No length restrictions enforced by Blazing Protostar. Consumers are responsible for managing suggestion length (truncation, etc.) if needed.

**Text Overlap**: Since ghost text is rendered using `TextSpan`, Flutter's text layout engine handles positioning automatically. No special overlap handling needed.

**Performance**: Rapid `setGhostText()` calls (e.g., on every keystroke) are expected. Performance optimization (debouncing, etc.) is the responsibility of the consuming application.

---

## Implementation Phases

This feature will be implemented in three discrete phases, allowing for incremental testing and feedback.

### Phase 1: Ghost Text Overlay API

**Scope**: Basic ghost text rendering capability

**Features**:
- `ghostText` property on `MarkdownTextEditingController`
- `setGhostText()` and `clearGhostText()` methods
- Inline TextSpan rendering at cursor position
- Theme-based color styling
- Single-line support only
- Sanitization of special characters

**Acceptance Criteria**:
- [ ] `MarkdownTextEditingController` has `ghostText` property
- [ ] `setGhostText()` and `clearGhostText()` methods work correctly
- [ ] Ghost text renders at cursor position with theme-based grey color
- [ ] Ghost text is not selectable and doesn't interfere with editing
- [ ] Ghost text renders in raw mode (no markdown rendering)
- [ ] Special characters (newlines, tabs) are sanitized
- [ ] Unit tests: Ghost text property setters/getters, clearing
- [ ] Widget tests: Ghost text renders correctly, styling is correct, updates on controller changes
- [ ] Integration tests: Ghost text with real typing scenarios
- [ ] Documentation: `docs/autocomplete.md` created with API documentation and usage examples
- [ ] Documentation: README.md updated to link to autocomplete documentation

**Version**: Patch or minor (e.g., 0.2.1 or 0.3.0)

---

### Phase 2: Custom Key Event Handlers

**Scope**: Allow consumers to intercept key events for autocomplete acceptance

**Features**:
- `onKeyEvent` callback parameter on `MarkdownEditor`
- Key event interception before default handling
- Support for preventing default behavior

**Acceptance Criteria**:
- [ ] `MarkdownEditor` accepts `onKeyEvent` callback parameter
- [ ] Callback receives key events before default handling
- [ ] Returning `true` from callback prevents default behavior
- [ ] Tab, Enter, Shift+Enter, and Escape keys work as specified
- [ ] Unit tests: Key event handler invocation
- [ ] Widget tests: Key events trigger callbacks, prevention works correctly
- [ ] Integration tests: Key handlers with autocomplete workflow
- [ ] Documentation: `docs/autocomplete.md` updated with key event handler documentation

**Version**: Minor (e.g., 0.3.0 or 0.4.0)

---

### Phase 3: Text Manipulation Helpers

**Scope**: Enhanced text manipulation for accepting suggestions

**Features**:
- `replaceRange()` method on `MarkdownTextEditingController`
- Replace text in a given range with proper cursor positioning

**Acceptance Criteria**:
- [ ] `replaceRange()` method works correctly
- [ ] Cursor positions correctly after replacement
- [ ] Unit tests: Text replacement helpers
- [ ] Widget tests: Text replacement with various range values
- [ ] Documentation: `docs/autocomplete.md` updated with text manipulation helper documentation

**Version**: Patch (e.g., 0.3.1 or 0.4.1)

**Note**: This phase is optional if `insertAtCursor()` is sufficient for the autocomplete use case.

---

## Version Planning Summary

- **Phase 1**: Minor version bump (adds new API surface)
- **Phase 2**: Minor version bump (adds new API surface)  
- **Phase 3**: Patch version bump (enhancement to existing functionality)

Overall progression example: `0.2.0` → `0.3.0` (Phase 1) → `0.4.0` (Phase 2) → `0.4.1` (Phase 3)

---

## Testing & Validation Strategy

Each phase should be validated using:

1. **Widget Tests**: Automated tests to verify functionality programmatically
2. **Example App**: Visual demonstration app in `example/` directory showing the feature in action

**Example App Requirements**:
- Simple Flutter app with `MarkdownEditor`
- Demonstrates ghost text rendering (Phase 1)
- Demonstrates key event handling for autocomplete workflow (Phase 2)
- Shows text manipulation helpers (Phase 3)
- Allows manual testing and visual validation
- Serves as reference implementation for consumers

**Testing Checklist** (per phase):
- [ ] All acceptance criteria met
- [ ] Widget tests pass
- [ ] Example app demonstrates feature
- [ ] Manual testing in example app confirms expected behavior

---

## Autocomplete Trigger Strategies (Consumer-Specific)

The Blazing Protostar library provides the rendering mechanism (ghost text) and interaction hooks (key events), but **does not dictate when or how autocomplete suggestions are triggered**. Different consuming applications can implement different strategies:

**Possible Approaches**:
- **Immediate (Type A)**: Show suggestions as soon as trigger character (`:`) is typed
- **Progressive (Type B)**: Wait for a few characters before showing suggestions (e.g., `:you` → suggest `:youtube`)
- **Debounced (Type D)**: Wait X milliseconds after typing stops before computing/showing suggestions
- **Explicit (Type C)**: Require hotkey (Ctrl+Space) to trigger suggestions

**Resonant Bohr**: Will likely use Type A/B and/or D (automatic triggering with optional debouncing)

**Other Apps**: May prefer Type C (explicit trigger) for different UX requirements

---

## Questions for Resonant Bohr Team

1. ~~Are there any other editor capabilities needed for autocomplete?~~ ✓ Covered
2. ~~Should ghost text support multi-line suggestions, or just single-line?~~ ✓ Single-line for MVP
3. ~~Any specific styling requirements beyond grey color?~~ ✓ Theme-based

---

## Future Enhancements (Out of Scope for MVP)

The following features are not planned for the initial implementation but may be considered in future iterations:

### Multiple Suggestions Dropdown

**Scope**: Instead of single inline ghost text, show a dropdown/popup with multiple autocomplete options.

**Status**: Not currently planned, but potentially useful in the future.

**Design Consideration**: Would require additional UI components (overlay, list rendering, selection handling). The current ghost text API could coexist with a future dropdown API.

---

### Image Autocomplete

**Scope**: Autocomplete suggestions for image syntax `![alt](url)`.

**Status**: Likely useful for markdown editing workflows.

**Implementation**: Can be built using the current ghost text API - Resonant Bohr would detect `![` and provide appropriate suggestions. No additional Blazing Protostar features needed.

---

### Context-Aware Suggestions

**Scope**: Providing suggestions based on cursor position and document structure (e.g., only suggest headings at start of line, only suggest inline directives within paragraphs).

**Status**: Fully supported by current proposal.

**Implementation**: Resonant Bohr analyzes document structure and cursor position using existing parsing APIs to determine what suggestions are valid. Blazing Protostar just renders the provided suggestion as ghost text. No additional library features needed.

---

### Template/Snippet Expansion

**Scope**: Multi-line autocomplete like tables, code blocks, etc.

**Status**: Not planned, but developers can implement this using the current API.

**Implementation**: Consumers can use `insertAtCursor()` or `replaceRange()` (Phase 3) to insert multi-line content when accepting a suggestion. Ghost text would only show the first line (single-line MVP limitation).

**Future**: Multi-line ghost text support could enable better preview of template expansions.

---

## Next Steps

This requirements document is now complete. The implementation workflow for each phase should be:

### Phase 1: Ghost Text Overlay API
1. Implement ghost text properties and methods in `MarkdownTextEditingController`
2. Implement TextSpan rendering in `buildTextSpan()` method
3. Add sanitization logic for special characters
4. Create example app demonstrating ghost text
5. Write widget tests for ghost text rendering
6. Write unit tests for ghost text API
7. Create `docs/autocomplete.md` with API documentation
8. Update `README.md` to link to autocomplete docs
9. Publish new version (e.g., 0.3.0)

### Phase 2: Custom Key Event Handlers
1. Add `onKeyEvent` callback parameter to `MarkdownEditor`
2. Implement Focus widget integration for key event capture
3. Update example app to demonstrate key event handling
4. Write widget tests for key event callbacks
5. Write unit tests for key event handler invocation
6. Update `docs/autocomplete.md` with key event handler documentation
7. Publish new version (e.g., 0.4.0)

### Phase 3: Text Manipulation Helpers (Optional)
1. Implement `replaceRange()` method in `MarkdownTextEditingController`
2. Update example app to demonstrate text replacement
3. Write widget tests for text replacement
4. Write unit tests for `replaceRange()`
5. Update `docs/autocomplete.md` with helper method documentation
6. Publish new version (e.g., 0.4.1)

### Integration in Resonant Bohr
- Can begin after Phase 2 is complete (Phase 1 + Phase 2 provide full autocomplete workflow)
- Phase 3 is optional enhancement - evaluate need based on Phase 1/2 experience
