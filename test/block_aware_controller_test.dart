import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  group('MarkdownTextEditingController Block-Awareness', () {
    test('Initializes blocks correctly from text', () {
      final controller = MarkdownTextEditingController(
        text: '# Header\n\nParagraph',
      );
      expect(controller.blocks.length, 3);
      expect(controller.blocks[0].type, 'header');
      expect(controller.blocks[1].text, '');
      expect(controller.blocks[2].text, 'Paragraph');
    });

    test('Maps global offsets to local offsets correctly', () {
      final controller = MarkdownTextEditingController(text: 'ABC\nDE');
      // Indices:
      // 0: A
      // 1: B
      // 2: C
      // 3: \n
      // 4: D
      // 5: E

      // Block 0: "ABC" (len 3)
      // Block 1: "DE" (len 2)

      expect(controller.mapGlobalToLocalOffset(0), (0, 0));
      expect(controller.mapGlobalToLocalOffset(1), (0, 1));
      expect(controller.mapGlobalToLocalOffset(2), (0, 2));
      expect(controller.mapGlobalToLocalOffset(3), (0, 3)); // End of Block 0

      // The newline at index 3.
      // Our logic: if offset == blockEnd + 1, and i < blocks.length - 1, return (i+1, 0)
      // Wait, 3 == blockEnd (which is 0 + 3).
      // If we pass 4:
      // currentOffset (Block 0) = 0. blockEnd = 3.
      // offset 4 is > blockEnd.
      // i = 0 check: globalOffset (4) == blockEnd (3) + 1. It matches!
      // Returns (1, 0).
      expect(controller.mapGlobalToLocalOffset(4), (1, 0));
      expect(controller.mapGlobalToLocalOffset(5), (1, 1));
      expect(controller.mapGlobalToLocalOffset(6), (1, 2)); // End of Block 1
    });

    test('updates blocks when text changes', () {
      final controller = MarkdownTextEditingController(text: 'A');
      expect(controller.blocks.length, 1);

      controller.text = 'A\nB';
      expect(controller.blocks.length, 2);
      expect(controller.blocks[1].text, 'B');
    });
  });
}
