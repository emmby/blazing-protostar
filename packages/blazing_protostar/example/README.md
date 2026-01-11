# Blazing Protostar Example

This example demonstrates how to use the `blazing_protostar` package to integrate a rich Markdown editor into your Flutter application.

## Features Demonstrated

- **Markdown Editing**: Full support for standard Markdown syntax.
- **WYSIWYG Mode**: Visual styling directly in the editor.
- **Toolbar**: Formatting actions (Bold, Italic, Links, Headers).
- **Flexible Layout**: Usage in both full-screen and form-based layouts.

## Basic Usage

The core of the package is the `MarkdownEditor` widget and its controller, `MarkdownTextEditingController`.

```dart
import 'package:blazing_protostar/blazing_protostar.dart';

class MyEditorScreen extends StatefulWidget {
  @override
  _MyEditorScreenState createState() => _MyEditorScreenState();
}

class _MyEditorScreenState extends State<MyEditorScreen> {
  late MarkdownTextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize with optional initial text
    _controller = MarkdownTextEditingController(text: '# Hello World');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Markdown Editor')),
      body: MarkdownEditor(
        controller: _controller,
        // Optional Configuration:
        toolbarVisible: true, // Show/Hide toolbar
        readOnly: false, // Enable/Disable editing
        expands: true, // True for full-screen, False for forms
        padding: const EdgeInsets.all(16.0),
      ),
    );
  }
}
```

## Form Usage

To use the editor inside a form or scrollable list, set `expands: false` and provide constraints like `minLines` or `maxLines`.

```dart
MarkdownEditor(
  controller: _controller,
  expands: false,
  minLines: 5,
  maxLines: 10, // Or null to grow indefinitely
  decoration: InputDecoration(
    border: OutlineInputBorder(),
    hintText: 'Enter description...',
  ),
)
```

## Data Access

Access the raw markdown text using the controller:

```dart
String currentText = _controller.text;
```
