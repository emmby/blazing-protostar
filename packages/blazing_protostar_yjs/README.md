# blazing_protostar_yjs

A Yjs backend implementation for the Blazing Protostar Markdown Editor. This package enables real-time collaboration by connecting the editor to a `Y.Doc`.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  blazing_protostar_yjs: ^0.1.0
```

## Developer Guide

### Core Concepts

This package serves as a bridge between the **Dart** world (Blazing Protostar Editor) and the **JavaScript/Yjs** world (Y.Doc, Y.Text).

- **`YDoc`**: Represents the shared document. It is a Dart extension type wrapper around the JS `Y.Doc`.
- **`YjsDocumentBackend`**: An implementation of `DocumentBackend` that syncs editor changes to a `Y.Doc`.

### API Reference

#### 1. YDoc & YText
Wrappers around standard Yjs objects provided via `dart:js_interop`.

```dart
// Create a new YDoc (or wrap an existing JS handle)
final doc = YDoc();

// Access shared data types from anywhere in the doc
final yText = doc.getText('markdown-content');
final yMap = doc.getMap('metadata');
```

#### 2. YjsDocumentBackend
The main class you will interact with. It binds the editor to a Yjs document.

```dart
class YjsDocumentBackend extends DocumentBackend {
  YjsDocumentBackend(YText yText);
}
```

### Usage Guide

This package is **provider-agnostic**. You are responsible for creating the `Y.Doc` and connecting it to a provider (e.g., `y-websocket`, `y-webrtc`).

#### 1. Integration

```dart
import 'package:blazing_protostar/blazing_protostar.dart'; // Core Editor
import 'package:blazing_protostar_yjs/blazing_protostar_yjs.dart'; // Yjs Backend
import 'dart:js_interop';

// ... inside your widget

void _setupEditor() {
  // 1. Create the YDoc
  final yDoc = YDoc();

  // 2. Connect to a Provider (using JS interop)
  // Example: connect to y-websocket (assuming it's loaded in index.html)
  // connectToWebsocket(yDoc, 'wss://demos.yjs.dev', 'my-roomname');

  // 3. Create the Backend with the specific YText
  final yText = yDoc.getText('markdown-content');
  final backend = YjsDocumentBackend(yText);

  // 4. Initialize Controller with this backend
  _controller = MarkdownTextEditingController(backend: backend);
}
```

#### 2. Connecting Providers (Web)

Since Yjs providers are JavaScript libraries, you typically need to use `dart:js_interop` to wire them up.

Example `web/index.html`:
```html
<script src="https://unpkg.com/yjs@13.0.0/dist/yjs.js"></script>
<script src="https://unpkg.com/y-websocket@1.0.0/dist/y-websocket.js"></script>
<script>
  // Helper to attach provider
  window.connectWebsocket = function(doc, url, room) {
    new Y.WebsocketProvider(url, room, doc);
  }
</script>
```

Example Dart Wiring:
```dart
@JS('connectWebsocket')
external void connectWebsocket(YDoc doc, String url, String room);

// Call it
connectWebsocket(yDoc, 'wss://demos.yjs.dev', 'my-room');
```

## Running Tests

To run the tests for this package:

```bash
flutter test
```
