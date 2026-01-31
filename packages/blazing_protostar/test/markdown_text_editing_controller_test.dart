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

  test(
    'value setter handles text replacement with different length without error',
    () {
      final controller = MarkdownTextEditingController(text: 'short');
      controller.selection = const TextSelection.collapsed(offset: 5);

      // Replace with longer text - this would trigger the bug before the fix
      controller.value = controller.value.copyWith(
        text: 'much longer text here',
        selection: const TextSelection.collapsed(offset: 21),
      );

      expect(controller.text, 'much longer text here');
      expect(controller.selection.baseOffset, 21);
    },
  );

  test(
    'value setter handles shorter replacement text without assertion error',
    () {
      final controller = MarkdownTextEditingController(
        text: ':child[target-uuid-123]',
      );
      controller.selection = const TextSelection.collapsed(offset: 23);

      // Simulate autocomplete replacement with different length
      // This triggers backend.delete() -> notifyListeners() -> _onBackendChanged()
      controller.value = controller.value.copyWith(
        text: ':child[Tar',
        selection: const TextSelection.collapsed(offset: 10),
      );

      expect(controller.text, ':child[Tar');
      expect(controller.selection.baseOffset, 10);
    },
  );
}
