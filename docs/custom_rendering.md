# Custom Rendering

Blazing Protostar provides a unified **Custom Rendering API** that enables developers to override the rendering of any Markdown AST node type. This allows you to customize how headers, bold text, links, directives, or any other element is displayed—from simple style changes to complex widget replacements.

## Overview

The Custom Rendering API uses a **type-based registry** where you map AST node types (like `HeaderNode`, `BoldNode`, etc.) to custom renderer functions. This gives you full control over how specific markdown elements appear in the editor.

### Key Features

- **Unified API**: Single system for overriding both standard elements (headers, links) and custom elements (directives)
- **Type-Based Registration**: Register renderers by AST Node type (`HeaderNode`, `BoldNode`, etc.)
- **Edit/View Mode Support**: `isRevealed` parameter enables different rendering based on cursor proximity
- **Widget Support**: Return `WidgetSpan` to embed custom Flutter widgets (chips, buttons, etc.)
- **Zero Configuration**: Default rendering preserved when no custom renderers are provided

## Core API

### NodeRenderer Typedef

```dart
typedef NodeRenderer = InlineSpan Function(
  BuildContext context,
  Node node,
  TextStyle style,
  bool isRevealed,
);
```

**Parameters:**
- `context`: Build context for widget creation
- `node`: The AST node being rendered (cast to specific type like `HeaderNode`)
- `style`: Base text style that would have been applied by default renderer
- `isRevealed`: `true` if cursor is near/inside this node (Edit Mode), `false` otherwise

### Usage

Pass the `nodeBuilders` map to `MarkdownTextEditingController`:

```dart
final controller = MarkdownTextEditingController(
  text: '# Hello World',
  nodeBuilders: {
    HeaderNode: (context, node, style, isRevealed) {
      final header = node as HeaderNode;
      // Extract text from child TextNodes
      final text = header.children
          .whereType<TextNode>()
          .map((e) => e.text)
          .join();
      
      return TextSpan(
        text: text,
        style: style.copyWith(
          color: Colors.purple,
          fontWeight: FontWeight.bold,
        ),
      );
    },
  },
);
```

## Common Use Cases

### 1. Custom Header Colors

```dart
nodeBuilders: {
  HeaderNode: (context, node, style, isRevealed) {
    final header = node as HeaderNode;
    final text = header.children
        .whereType<TextNode>()
        .map((e) => e.text)
        .join();
    
    // Different colors based on level
    final color = switch (header.level) {
      1 => Colors.red,
      2 => Colors.orange,
      3 => Colors.green,
      _ => Colors.blue,
    };
    
    return TextSpan(
      text: text,
      style: style.copyWith(color: color),
    );
  },
}
```

### 2. Custom Directive Widgets (Chips)

```dart
nodeBuilders: {
  InlineDirectiveNode: (context, node, style, isRevealed) {
    final directive = node as InlineDirectiveNode;
    
    // Edit Mode: Show raw syntax for editing
    if (isRevealed) {
      return TextSpan(
        text: ':${directive.name}[${directive.content}]',
        style: style.copyWith(color: Colors.grey),
      );
    }
    
    // View Mode: Show as a chip widget
    return WidgetSpan(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          directive.content,
          style: TextStyle(color: Colors.blue),
        ),
      ),
    );
  },
}
```

### 3. Custom Link Rendering

```dart
nodeBuilders: {
  LinkNode: (context, node, style, isRevealed) {
    final link = node as LinkNode;
    
    return WidgetSpan(
      child: GestureDetector(
        onTap: () {
          // Handle link click
          print('Navigate to: ${link.url}');
        },
        child: Text(
          link.text,
          style: style.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  },
}
```

### 4. Rainbow Text (Multi-Color Rendering)

```dart
nodeBuilders: {
  BoldNode: (context, node, style, isRevealed) {
    final bold = node as BoldNode;
    final text = bold.children
        .whereType<TextNode>()
        .map((e) => e.text)
        .join();
    
    // Create rainbow gradient effect
    final colors = [Colors.red, Colors.orange, Colors.yellow, 
                    Colors.green, Colors.blue, Colors.purple];
    
    return TextSpan(
      children: text.split('').asMap().entries.map((entry) {
        return TextSpan(
          text: entry.value,
          style: style.copyWith(
            color: colors[entry.key % colors.length],
            fontWeight: FontWeight.bold,
          ),
        );
      }).toList(),
    );
  },
}
```

## Edit Mode vs View Mode

The `isRevealed` parameter enables different rendering based on cursor position. This integrates with the [WYSIWYG Mode](v003_wysiwyg.md) to provide seamless Edit/View transitions.


```dart
HeaderNode: (context, node, style, isRevealed) {
  final header = node as HeaderNode;
  final text = header.children
      .whereType<TextNode>()
      .map((e) => e.text)
      .join();
  
  if (isRevealed) {
    // Edit Mode: Show with markers visible (or different style)
    return TextSpan(
      text: '#' * header.level + ' ' + text,
      style: style.copyWith(color: Colors.grey),
    );
  }
  
  // View Mode: Custom rainbow style
  return TextSpan(
    text: text,
    style: style.copyWith(
      foreground: Paint()
        ..shader = LinearGradient(
          colors: [Colors.purple, Colors.pink],
        ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
    ),
  );
}
```

## Available Node Types

You can register custom renderers for any of these node types:

### Block Nodes
- `HeaderNode` - Headers (# to ######)
- `ParagraphNode` - Paragraphs
- `UnorderedListNode` - Unordered lists
- `OrderedListNode` - Ordered lists
- `ListItemNode` - Individual list items

### Inline Nodes
- `BoldNode` - Bold text (**)
- `ItalicNode` - Italic text (*)
- `LinkNode` - Links ([text](url))
- `InlineDirectiveNode` - Custom directives (:name[content])

### Other Nodes
- `TextNode` - Raw text (rare to override)
- `DocumentNode` - Root document node

## Extracting Text from Nodes

Most `ElementNode` types don't have a direct `text` property. Extract text from children:

```dart
final text = node.children
    .whereType<TextNode>()
    .map((e) => e.text)
    .join();
```

## Performance Considerations

- Custom renderers are called during every `buildTextSpan()` (on each keystroke)
- Keep renderer logic lightweight
- Avoid expensive computations or network calls
- For complex widgets, consider caching strategies

## Backwards Compatibility

The older `directiveBuilders` API (Map<String, DirectiveBuilder>) remains supported for directive-specific rendering:

```dart
final controller = MarkdownTextEditingController(
  directiveBuilders: {
    'child': (context, node) {
      return WidgetSpan(child: Chip(label: Text(node.content)));
    },
  },
);
```

However, the new `nodeBuilders` API is more flexible and recommended for new code.

## Complete Example

```dart
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:flutter/material.dart';

class CustomRenderingDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = MarkdownTextEditingController(
      text: '''
# Purple Header
This is **rainbow bold** text.
Visit [our site](https://example.com)
Use :tag[custom] directives
''',
      nodeBuilders: {
        // Purple headers
        HeaderNode: (ctx, node, style, isRevealed) {
          final text = (node as HeaderNode).children
              .whereType<TextNode>()
              .map((e) => e.text)
              .join();
          return TextSpan(
            text: text,
            style: style.copyWith(color: Colors.purple),
          );
        },
        
        // Rainbow bold
        BoldNode: (ctx, node, style, isRevealed) {
          final text = (node as BoldNode).children
              .whereType<TextNode>()
              .map((e) => e.text)
              .join();
          final colors = [Colors.red, Colors.orange, Colors.yellow];
          return TextSpan(
            children: text.split('').asMap().entries.map((e) {
              return TextSpan(
                text: e.value,
                style: style.copyWith(
                  color: colors[e.key % colors.length],
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          );
        },
        
        // Custom directive chips
        InlineDirectiveNode: (ctx, node, style, isRevealed) {
          final directive = node as InlineDirectiveNode;
          if (isRevealed) {
            return TextSpan(text: ':${directive.name}[${directive.content}]');
          }
          return WidgetSpan(
            child: Chip(label: Text(directive.content)),
          );
        },
      },
    );

    return Scaffold(
      body: MarkdownEditor(controller: controller),
    );
  }
}
```

## Testing Custom Renderers

When testing custom renderers, remember to:

1. Test with `isRevealed` both `true` and `false`
2. Verify the returned `InlineSpan` structure
3. Test edge cases (empty text, special characters)
4. Ensure no performance regressions with large documents

See `test/features/editor/custom_rendering_test.dart` for reference test implementations.
