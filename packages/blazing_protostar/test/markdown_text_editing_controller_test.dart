import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  test(
    'MarkdownTextEditingController.getCurrentHeadingLevel handles cursor at end of document',
    () {
      final controller = MarkdownTextEditingController(text: 'Hello');

      // Set cursor to the very end of the text (offset == length)
      // This is valid and should not crash
      controller.selection = const TextSelection.collapsed(offset: 5);

      try {
        final level = controller.getCurrentHeadingLevel();
        expect(level, 0);
      } catch (e) {
        fail('Should not throw exception: $e');
      }
    },
  );

  test(
    'MarkdownTextEditingController.applyHeadingLevel handles cursor at end of document',
    () {
      final controller = MarkdownTextEditingController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: 5);

      // Applying header should work
      controller.applyHeadingLevel(1);
      expect(controller.text, '# Hello');
    },
  );

  test(
    'MarkdownTextEditingController.insertAtCursor inserts text at cursor',
    () {
      final controller = MarkdownTextEditingController(text: 'Hello World');

      // Insert in the middle
      controller.selection = const TextSelection.collapsed(offset: 6);
      controller.insertAtCursor('Beautiful ');
      expect(controller.text, 'Hello Beautiful World');
      expect(controller.selection.baseOffset, 16); // After inserted text
    },
  );

  test('MarkdownTextEditingController.insertAtCursor replaces selection', () {
    final controller = MarkdownTextEditingController(text: 'Hello World');

    // Select "World"
    controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);
    controller.insertAtCursor('Flutter');
    expect(controller.text, 'Hello Flutter');
    expect(controller.selection.baseOffset, 13); // After inserted text
  });

  test('MarkdownTextEditingController.insertAtCursor handles no selection', () {
    final controller = MarkdownTextEditingController(text: 'Hello');

    // Invalid selection
    controller.selection = const TextSelection.collapsed(offset: -1);
    controller.insertAtCursor('Test');
    expect(controller.text, 'Hello'); // No change
  });
}
