import 'dart:math';
import 'package:flutter/material.dart';
import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:blazing_protostar_yjs/blazing_protostar_yjs.dart';

/// A test widget that renders two markdown editors side-by-side, each with its
/// own YjsDocumentBackend. Both backends share the same Y.Doc via BroadcastChannel.
///
/// This is used for convergence testing - both editors should always show
/// the same text after sync.
class DualEditorTest extends StatefulWidget {
  const DualEditorTest({super.key});

  @override
  State<DualEditorTest> createState() => DualEditorTestState();
}

class DualEditorTestState extends State<DualEditorTest> {
  late MarkdownTextEditingController controller1;
  late MarkdownTextEditingController controller2;
  YjsDocumentBackend? backend1;
  YjsDocumentBackend? backend2;
  String? error;
  bool testRunning = false;
  String testResult = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    try {
      backend1 = YjsBackend.create() as YjsDocumentBackend;
      backend2 = YjsBackend.create() as YjsDocumentBackend;
      controller1 = MarkdownTextEditingController(backend: backend1);
      controller2 = MarkdownTextEditingController(backend: backend2);
    } catch (e) {
      error = e.toString();
      controller1 = MarkdownTextEditingController();
      controller2 = MarkdownTextEditingController();
    }
  }

  /// Runs the convergence fuzz test.
  /// Returns true if both editors have identical text after all operations.
  Future<bool> runConvergenceFuzzTest({
    int iterations = 50,
    int seed = 42,
  }) async {
    if (backend1 == null || backend2 == null) {
      setState(() => testResult = 'Error: Yjs backends not available');
      return false;
    }

    setState(() {
      testRunning = true;
      testResult = 'Running...';
    });

    final random = Random(seed);

    // Clear both editors first
    controller1.text = '';
    await Future.delayed(const Duration(milliseconds: 50));
    controller2.text = '';
    await Future.delayed(const Duration(milliseconds: 50));

    for (var i = 0; i < iterations; i++) {
      // Alternate between editors, or randomly pick one
      final targetController = random.nextBool() ? controller1 : controller2;
      final currentText = targetController.text;

      // Random operation: insert, delete, or replace
      final op = random.nextInt(3);

      if (op == 0 || currentText.isEmpty) {
        // Insert random text at random position
        final pos = currentText.isEmpty
            ? 0
            : random.nextInt(currentText.length + 1);
        final chars = String.fromCharCodes(
          List.generate(random.nextInt(3) + 1, (_) => random.nextInt(26) + 97),
        );
        targetController.text =
            currentText.substring(0, pos) + chars + currentText.substring(pos);
      } else if (op == 1 && currentText.isNotEmpty) {
        // Delete random character
        final pos = random.nextInt(currentText.length);
        targetController.text =
            currentText.substring(0, pos) + currentText.substring(pos + 1);
      } else if (currentText.isNotEmpty) {
        // Replace random character
        final pos = random.nextInt(currentText.length);
        final char = String.fromCharCode(random.nextInt(26) + 65); // A-Z
        targetController.text =
            currentText.substring(0, pos) +
            char +
            currentText.substring(pos + 1);
      }

      // Small delay to allow sync
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Wait for final sync
    await Future.delayed(const Duration(milliseconds: 200));

    final text1 = controller1.text;
    final text2 = controller2.text;
    final converged = text1 == text2;

    setState(() {
      testRunning = false;
      testResult = converged
          ? 'PASS: Both editors converged to identical text (${text1.length} chars)'
          : 'FAIL: Texts differ!\nEditor 1: $text1\nEditor 2: $text2';
    });

    return converged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual Editor Convergence Test'),
        actions: [
          IconButton(
            key: const Key('run_test'),
            icon: testRunning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            onPressed: testRunning ? null : () => runConvergenceFuzzTest(),
            tooltip: 'Run Convergence Test',
          ),
        ],
      ),
      body: error != null
          ? Center(child: Text('Error: $error'))
          : Column(
              children: [
                if (testResult.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: testResult.startsWith('PASS')
                        ? Colors.green.shade100
                        : testResult.startsWith('FAIL')
                        ? Colors.red.shade100
                        : Colors.blue.shade100,
                    child: Text(
                      testResult,
                      key: const Key('test_result'),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMarkdownEditor(
                          'Editor 1 (User A)',
                          controller1,
                          const Key('editor1'),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _buildMarkdownEditor(
                          'Editor 2 (User B)',
                          controller2,
                          const Key('editor2'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Builds a complete markdown editor with toolbar and text field.
  Widget _buildMarkdownEditor(
    String title,
    MarkdownTextEditingController controller,
    Key key,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade200,
          width: double.infinity,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Markdown Toolbar
        MarkdownToolbar(controller: controller),
        const Divider(height: 1),
        // Markdown Editor
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: TextField(
              key: key,
              controller: controller,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller1.dispose();
    controller2.dispose();
    super.dispose();
  }
}
