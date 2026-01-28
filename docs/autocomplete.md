# Autocomplete

Blazing Protostar provides a **Ghost Text Overlay API** to support inline autocomplete suggestions. This feature is designed to allow consuming applications (like Resonant Bohr) to implement custom autocomplete logic while handling the complex rendering of overlay text within the editor text stream.

## Ghost Text API

The autocomplete functionality is exposed primarily through the `MarkdownTextEditingController`.

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `ghostText` | `String?` | The current ghost text suggestion displayed at the cursor position. `null` if no suggestion is active. |

### Methods

| Method | Description |
|--------|-------------|
| `setGhostText(String? text)` | Sets the ghost text to display. The input is automatically cleaned (newlines/tabs \u2192 spaces, control chars stripped) before rendering. |
| `clearGhostText()` | Clears the current ghost text suggestion. |

## Usage Example

See `example/lib/autocomplete_demo.dart` for a complete runnable example.

Consumers are responsible for listening to text changes, determining if an autocomplete suggestion is available, and setting the ghost text.

```dart
// Run the demo:
// flutter run -t lib/autocomplete_demo.dart
final controller = MarkdownTextEditingController();

controller.addListener(() {
  final text = controller.text;
  final selection = controller.selection;
  
  // 1. Check if we have a valid cursor position for autocomplete
  if (!selection.isValid || !selection.isCollapsed) {
    controller.clearGhostText();
    return;
  }
  
  // 2. Analyze text before cursor to find triggers
  // (Simplified example)
  if (text.endsWith(':you')) {
    // 3. Set the suggestion (ghost text)
    // The user has typed ":you", we suggest "tube"
    controller.setGhostText('tube');
  } else {
    controller.clearGhostText();
  }
});
```

## Rendering Behavior

- **Positioning**: Ghost text is rendered inline using `TextSpan` immediately after the cursor.
- **Styling**: Ghost text uses the current text style color with **0.4 opacity**. It automatically adapts to light/dark themes.
- **Raw Mode**: Ghost text is always rendered as raw text, even if the suggested text contains markdown syntax (e.g., `**bold**` or `:directive`).
- **Sanitization**: To prevent rendering issues, newlines (`\n`) and tabs (`\t`) in the ghost text are replaced with spaces. Control characters are stripped.

## Lifecycle Management

**The consuming application is responsible for clearing the ghost text.**

Blazing Protostar does **not** automatically clear ghost text when the user types or moves the cursor. You must call `clearGhostText()` in your listener logic when:
- The user moves the cursor away from the trigger position.
- The user types a character that invalidates the suggestion.
- The user accepts the suggestion (handled by the consuming application).

## Suggestion Acceptance

Handling key events (like `Tab` or `Enter`) and replacing the text with the suggestion is currently the responsibility of the consuming application. Blazing Protostar provides the building blocks (controller and ghost text), but the specific interaction model is left to the implementer.
