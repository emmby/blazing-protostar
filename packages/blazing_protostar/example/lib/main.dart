import 'package:flutter/material.dart';
import 'package:blazing_protostar/blazing_protostar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal Markdown Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MinimalEditorExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MinimalEditorExample extends StatefulWidget {
  const MinimalEditorExample({super.key});

  @override
  State<MinimalEditorExample> createState() => _MinimalEditorExampleState();
}

class _MinimalEditorExampleState extends State<MinimalEditorExample> {
  // 1. Create the controller
  late final MarkdownTextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // 2. Initialize it with some starting text
    _controller = MarkdownTextEditingController(
      text:
          '# Hello World\n\nThis is a minimal example of the **Blazing Protostar** editor.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Example')),
      // 3. Use the MarkdownEditor widget
      body: MarkdownEditor(
        controller: _controller,
        // Optional configuration:
        // toolbarVisible: true,
        // readOnly: false,
      ),
    );
  }
}
