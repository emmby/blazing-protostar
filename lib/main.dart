import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_editor_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Markdown Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MarkdownEditorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
