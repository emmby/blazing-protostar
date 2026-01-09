import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_toolbar.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> {
  late final MarkdownTextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MarkdownTextEditingController(
      text:
          '# Welcome to the Markdown Editor\n\n'
          'Try typing some **bold** or *italic* text.\n\n'
          '- This is a list item\n'
          '- Another list item\n\n'
          'You can also add [links](https://flutter.dev).',
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
      appBar: AppBar(
        title: const Text('Markdown Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Markdown Editor',
                applicationVersion: '0.1.0',
                children: [
                  const Text('A robust CommonMark editor for Flutter.'),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          MarkdownToolbar(controller: _controller),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing...',
                ),
                autofocus: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
