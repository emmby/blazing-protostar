import 'package:flutter/material.dart';
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/blazing_protostar_yjs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yjs Markdown Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EditorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditorHome extends StatefulWidget {
  const EditorHome({super.key});

  @override
  State<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<EditorHome> {
  late final MarkdownTextEditingController _controller;
  YjsDocumentBackend? _yjsBackend;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    // 1. Create a YDoc (from blaze_protostar_yjs export)
    // In a real app, you might want to create this in a provider/service.
    final doc = YDoc();

    // 2. Wire up a Provider (Example)
    // ---------------------------------------------------------
    // Since this is client-side only for the demo, we don't have a real
    // WebSocket provider. In a real app, you would do something like:
    //
    // import 'package:y_websocket/y_websocket.dart';
    // final provider = WebsocketProvider('ws://localhost:1234', 'room-name', doc);
    //
    // Or if using raw JS interop for y-websocket:
    // final wsProvider = WebsocketProvider('ws://...', 'room', doc);
    // ---------------------------------------------------------

    // 3. Create the Backend formatted for Blazing Protostar
    // This connects the specific YDoc field to our editor.
    _yjsBackend = YjsDocumentBackend(doc, fieldName: 'markdown-content');

    // 4. Initialize Controller with the backend
    _controller = MarkdownTextEditingController(backend: _yjsBackend!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yjs + Blazing Protostar'),
        actions: const [
          // Undo button
          IconButton(
            icon: Icon(Icons.undo),
            tooltip: 'Undo',
            // Note: In a real app, link this to Y.UndoManager
            onPressed: null,
          ),
          // Redo button
          IconButton(
            icon: Icon(Icons.redo),
            tooltip: 'Redo',
            // Note: In a real app, link this to Y.UndoManager
            onPressed: null,
          ),
        ],
      ),
      body: MarkdownEditor(controller: _controller),
    );
  }
}
