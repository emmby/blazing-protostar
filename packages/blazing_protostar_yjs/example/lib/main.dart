import 'package:flutter/material.dart';
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/blazing_protostar_yjs.dart';
import 'dual_editor_test.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const EditorHome(),
        '/dual_editor_test': (context) => const DualEditorTest(),
      },
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
  MarkdownTextEditingController? _controller;
  YjsDocumentBackend? _yjsBackend;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    DocumentBackend backend;
    try {
      // Use the clean factory method instead of dealing with JS objects.
      backend = YjsBackend.create();
      _yjsBackend = backend as YjsDocumentBackend;
    } catch (e) {
      backend = InMemoryBackend(
        initialText:
            'Yjs Backend initialization failed: $e\n\n'
            'Are you running on Web and have included yjs_bridge.js in your index.html?',
      );
    }
    _controller = MarkdownTextEditingController(backend: backend);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yjs + Blazing Protostar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Run Tests',
            onPressed: () => Navigator.pushNamed(context, '/dual_editor_test'),
          ),
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _yjsBackend != null
                ? () {
                    _yjsBackend!.undo();
                    setState(() {});
                  }
                : null,
          ),
          // Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _yjsBackend != null
                ? () {
                    _yjsBackend!.redo();
                    setState(() {});
                  }
                : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MarkdownToolbar(controller: _controller!),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
