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

To render a directive as a Flutter widget, you must provide a `DirectiveBuilder` to the `MarkdownTextEditingController`.

### 1. Define a Builder

A `DirectiveBuilder` is a function that takes a `BuildContext` and an `InlineDirectiveNode` and returns a `WidgetSpan`.

```dart
WidgetSpan userDirectiveBuilder(BuildContext context, InlineDirectiveNode node) {
  // Access content
  final content = node.children.map((n) => n.text).join();
  
  // Access arguments (if any)
  final userId = node.args;
  
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

### 2. Register the Builder

Pass a map of builders to your controller:

```dart
final controller = MarkdownTextEditingController(
  text: 'Hello :user[Mike]',
  directiveBuilders: {
    'user': userDirectiveBuilder,
    'button': (context, node) {
        // ... another builder
        return WidgetSpan(child: TextButton(onPressed: () {}, child: Text('Click')));
    },
  },
);
```

Now, `:user[Mike]` will render as a Chip, while `:other[thing]` will still render as raw text.
