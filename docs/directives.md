# Using Generic Inline Directives

Generic Inline Directives allow you to extend Markdown with custom widgets inline with text. The syntax matches the [CommonMark Generic Directives extension](https://talk.commonmark.org/t/generic-directives/2681).

## Syntax

The basic syntax is:
```markdown
:name[content](arguments){attributes}
```

- **:name** - The type of directive (e.g., `:user`, `:button`). Must start with a letter.
- **[content]** - Inline markdown text to be rendered or passed to the widget.
- **(arguments)** - Optional. A string argument (e.g., a URL or ID).
- **{attributes}** - Optional. Key-value pairs (e.g., `{color=red}`).

### Examples
- `:user[Mikem]` - Simple directive.
- `:mention[Mikem](123)` - Directive with an ID argument.
- `:button[Click Me]{style=primary}` - Directive with attributes.

## Default Behavior

By default, if you type a directive that is **not handled** by the editor, it will render **exactly as written** (as raw text).

Example:
Input: `Hello :foo[bar]`
Rendered: `Hello :foo[bar]`

This ensures that directives are an **opt-in** feature and don't accidentally hide text that looks like a directive.

## Custom Rendering

To render a directive as a Flutter widget, use the `nodeBuilders` parameter with `InlineDirectiveNode`.

### 1. Define a Renderer

A custom renderer for directives takes several parameters and returns an `InlineSpan` (usually a `WidgetSpan`).

```dart
InlineSpan userDirectiveRenderer(
  BuildContext context,
  Node node,
  TextStyle style,
  bool isRevealed,
) {
  final directive = node as InlineDirectiveNode;
  
  // Access content
  final content = directive.children
      .whereType<TextNode>()
      .map((n) => n.text)
      .join();
  
  // Access arguments (if any)
  final userId = directive.args;
  
  // Show raw text when editing (cursor nearby)
  if (isRevealed) {
    return TextSpan(
      text: ':${directive.name}[$content]',
      style: style.copyWith(color: Colors.grey),
    );
  }
  
  // Show custom widget in view mode
  return WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Chip(
      avatar: Icon(Icons.person, size: 16),
      label: Text(content),
      backgroundColor: Colors.blue.shade100,
    ),
  );
}
```

### 2. Register the Renderer

Pass the renderer to your controller using `nodeBuilders`:

```dart
final controller = MarkdownTextEditingController(
  text: 'Hello :user[Mike]',
  nodeBuilders: {
    InlineDirectiveNode: (context, node, style, isRevealed) {
      final directive = node as InlineDirectiveNode;
      final content = directive.children
          .whereType<TextNode>()
          .map((n) => n.text)
          .join();
      
      // You can check directive.name to handle different directives
      if (directive.name == 'user') {
        return WidgetSpan(
          child: Chip(
            avatar: Icon(Icons.person, size: 16),
            label: Text(content),
          ),
        );
      } else if (directive.name == 'button') {
        return WidgetSpan(
          child: TextButton(
            onPressed: () {},
            child: Text(content),
          ),
        );
      }
      
      // Fallback: render as raw text
      return TextSpan(text: ':${directive.name}[$content]');
    },
  },
);
```

Now, `:user[Mike]` will render as a Chip, `:button[Click]` as a button, and `:other[thing]` will render as raw text.

For more advanced custom rendering (including other node types like headers, bold, links, etc.), see [Custom Rendering](custom_rendering.md).
