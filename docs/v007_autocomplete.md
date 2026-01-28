# Blazing Protostar Autocomplete Prerequisites Specification

## Overview

This document specifies the features needed in the `blazing_protostar` library to support autocomplete functionality in Resonant Bohr. The autocomplete feature will be implemented in Resonant Bohr, but it requires certain rendering and interaction capabilities from the markdown editor library.

## Required Features

### 1. Ghost Text Overlay API

**Purpose**: Display inline autocomplete suggestions as greyed-out text after the cursor position.

**Requirements**:
- Render text overlay at the current cursor position
- Text should appear in a lighter/greyed color to distinguish it from actual content
- Ghost text should not be part of the actual document content
- Ghost text should update dynamically as the user types
- Ghost text should be dismissible

**Proposed API**:

```dart
class MarkdownTextEditingController extends TextEditingController {
  // ... existing properties ...
  
  /// Ghost text to display at cursor position
  /// Set to null or empty string to hide
  String? ghostText;
  
  /// Color for ghost text (default: Colors.grey.shade400)
  Color? ghostTextColor;
  
  /// Notify listeners when ghost text changes
  void setGhostText(String? text, {Color? color}) {
    ghostText = text;
    if (color != null) ghostTextColor = color;
    notifyListeners();
  }
  
  /// Clear ghost text
  void clearGhostText() {
    ghostText = null;
    notifyListeners();
  }
}
```

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

The ghost text can be implemented using a `Stack` widget in the `MarkdownEditor`:

```dart
Stack(
  children: [
    // Main text field
    TextField(...),
    
    // Ghost text overlay (conditional)
    if (controller.ghostText != null)
      Positioned(
        left: _calculateCursorPosition().dx,
        top: _calculateCursorPosition().dy,
        child: IgnorePointer(
          child: Text(
            controller.ghostText!,
            style: TextStyle(
              color: controller.ghostTextColor ?? Colors.grey.shade400,
              fontSize: _textStyle.fontSize,
              fontFamily: _textStyle.fontFamily,
            ),
          ),
        ),
      ),
  ],
)
```

### Key Event Handler Implementation

Use Flutter's `Focus` widget or `KeyboardListener` to capture key events:

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

---

## Testing Requirements

### Unit Tests
- [ ] Ghost text property setters/getters
- [ ] Ghost text clearing
- [ ] Key event handler invocation
- [ ] Text replacement helpers

### Widget Tests
- [ ] Ghost text renders at correct position
- [ ] Ghost text has correct styling
- [ ] Key events trigger callbacks
- [ ] Key event prevention works correctly
- [ ] Ghost text updates on controller changes

### Integration Tests
- [ ] Ghost text with real typing scenarios
- [ ] Key handlers with autocomplete workflow

---

## Acceptance Criteria

- [ ] `MarkdownTextEditingController` has `ghostText` property
- [ ] `MarkdownTextEditingController` has `setGhostText()` and `clearGhostText()` methods
- [ ] `MarkdownEditor` renders ghost text at cursor position in grey color
- [ ] Ghost text is not selectable and doesn't interfere with editing
- [ ] `MarkdownEditor` accepts `onKeyEvent` callback parameter
- [ ] Key events can be intercepted and default behavior prevented
- [ ] `replaceRange()` helper method works correctly
- [ ] All unit and widget tests pass
- [ ] Changes are published in a new version

---

## Version Planning

Suggested version bump: **Minor version** (e.g., 0.2.0 → 0.3.0) since this adds new API surface but doesn't break existing functionality.

---

## Questions for Resonant Bohr Team

1. Are there any other editor capabilities needed for autocomplete?
2. Should ghost text support multi-line suggestions, or just single-line?
3. Any specific styling requirements beyond grey color?
