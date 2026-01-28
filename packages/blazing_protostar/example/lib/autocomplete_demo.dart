import 'package:flutter/material.dart';
import 'package:blazing_protostar/blazing_protostar.dart';

void main() {
  runApp(const AutocompleteDemoApp());
}

class AutocompleteDemoApp extends StatelessWidget {
  const AutocompleteDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autocomplete Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const AutocompleteEditorExample(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AutocompleteEditorExample extends StatefulWidget {
  const AutocompleteEditorExample({super.key});

  @override
  State<AutocompleteEditorExample> createState() =>
      _AutocompleteEditorExampleState();
}

class _AutocompleteEditorExampleState extends State<AutocompleteEditorExample> {
  late final MarkdownTextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MarkdownTextEditingController(
      text:
          '# Autocomplete Demo\n\nType ":you" to see a suggestion.\n\nType ":warn" to see another.',
    );
    _controller.addListener(_checkForAutocomplete);
  }

  void _checkForAutocomplete() {
    final text = _controller.text;
    final selection = _controller.selection;

    // 1. Validation: Need collapsed selection to show ghost text
    if (!selection.isValid || !selection.isCollapsed) {
      _controller.clearGhostText();
      return;
    }

    final cursorIndex = selection.baseOffset;
    if (cursorIndex <= 0) {
      _controller.clearGhostText();
      return;
    }

    // 2. Trigger Extraction: Find word before cursor
    // Simple logic: look back until space or newline
    int start = cursorIndex - 1;
    while (start >= 0 && text[start] != ' ' && text[start] != '\n') {
      start--;
    }
    start++; // Move back to first char of word

    final currentWord = text.substring(start, cursorIndex);

    // 3. Suggestion Logic
    if (currentWord.startsWith(':')) {
      if (currentWord == ':you') {
        _controller.setGhostText('tube[video-id]');
      } else if (currentWord == ':youtube') {
        _controller.setGhostText('[video-id]');
      } else if (currentWord == ':warn') {
        _controller.setGhostText('ing');
      } else {
        _controller.clearGhostText();
      }
    } else {
      _controller.clearGhostText();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkForAutocomplete);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autocomplete Demo')),
      body: Column(
        children: [
          Expanded(
            child: MarkdownEditor(
              controller: _controller,
              padding: const EdgeInsets.all(16),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.purple.shade50,
            width: double.infinity,
            child: const Text(
              'Autocomplete Logic:\n'
              '• Type ":you" → Suggests "tube[video-id]"\n'
              '• Type ":warn" → Suggests "ing"\n'
              '• Ghost text appears in grey (0.4 opacity)',
              style: TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
