**Goal**: Enable developers to register custom renderers for markdown. This will be used to support custom directives (":") and other custom markdown elements. 

The existing rendering for standard commonmark should be customizable. By default it should behave as it does now, but developers should be able to register custom renderers for specific markdown elements if desired (eg. custom image rendering, custom link handling, etc.)


**Requirements**:
- **Unified API**: A single system must handle overriding standard elements (headers, links) and custom elements (directives).
- **Type-Based Registration**: Custom renderers should likely be registered by AST Node type (or similar identifier).


**Requirements**:
- **Unified API**: A single system must handle overriding standard elements (headers, links) and custom elements (directives).
- **Type-Based Registration**: Custom renderers are registered by AST Node type (e.g. `HeaderNode`, `BoldNode`).
- **Full Replacement**: Custom renderers completely replace the default rendering logic for that node.

## Technical Specification

### 1. API Usage
Consumers can provide a `nodeBuilders` map to the `MarkdownEditor`.

```dart
MarkdownEditor(
  nodeBuilders: {
    // Override Header Rendering
    HeaderNode: (context, node, style) {
      final header = node as HeaderNode;
      return TextSpan(
        text: header.text, 
        style: style.copyWith(color: Colors.red),
      );
    },
    // Override Bold Rendering
    BoldNode: (context, node, style) {
       return TextSpan(
         text: node.text,
         style: style.copyWith(background: Paint()..color = Colors.yellow),
       );
    },
  },
)
```

### 2. Architecture

#### `NodeRenderer` Typedef
```dart
typedef NodeRenderer = InlineSpan Function(
  BuildContext context, 
  Node node, 
  TextStyle style
);
```

#### `MarkdownTextEditingController`
The controller will hold the registry:
`final Map<Type, NodeRenderer> nodeBuilders;`

During the `_renderNode` pass, it will check:
```dart
if (nodeBuilders.containsKey(node.runtimeType)) {
  return nodeBuilders[node.runtimeType]!(context, node, currentStyle);
}
```

### 3. Supported Nodes
The following nodes will be exposed for overriding:
- `HeaderNode`
- `ParagraphNode`
- `BoldNode`
- `ItalicNode`
- `LinkNode`
- `UnorderedListNode` / `OrderedListNode` / `ListItemNode`
- `InlineDirectiveNode` (Existing `directiveBuilders` will be a helper on top of this).

### 4. Backwards Compatibility
- `directiveBuilders` (Map<String, DirectiveBuilder>) will remain supported. 
- Internally, the default renderer for `InlineDirectiveNode` will check this map.

