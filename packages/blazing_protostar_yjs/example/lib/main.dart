import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/blazing_protostar_yjs.dart';

@JS('YjsBridge')
external JSObject? get yjsBridge;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MarkdownTextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    DocumentBackend backend;
    if (yjsBridge != null) {
      backend = YjsDocumentBackend(yjsBridge as YjsBridge);
    } else {
      backend = InMemoryBackend(
        initialText: 'Yjs Bridge not found. Are you running on Web?',
      );
    }
    _controller = MarkdownTextEditingController(backend: backend);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yjs Markdown Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Yjs + Blazing Protostar')),
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
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
