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
}
