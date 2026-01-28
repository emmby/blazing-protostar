import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ghost Text Rendering', () {
    late MarkdownTextEditingController controller;

    setUp(() {
      controller = MarkdownTextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders ghost text at cursor position in empty document', (
      tester,
    ) async {
      controller.setGhostText('suggestion');
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      // Verify TextSpan tree contains ghost text
      final textFinder = find.byType(TextField);
      expect(textFinder, findsOneWidget);

      // We can't access buildTextSpan directly from the widget easily, but we can inspect the RichText descendant
      // OR we can manually invoke buildTextSpan on the controller since we have it.

      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(color: Colors.black),
        withComposing: false,
      );

      // Should be "suggestion" (empty doc + suggestion)
      // The implementation injects it.
      // span.text might be null if it has children.
      final textContent = span.toPlainText();
      expect(textContent, contains('suggestion'));

      // Verify structure using visitChildren
      bool foundGhostText = false;
      span.visitChildren((child) {
        if (child is TextSpan && child.text == 'suggestion') {
          foundGhostText = true;
          // Verify opacity
          expect(child.style?.color?.a, closeTo(0.4, 0.01));
          return false; // stop visiting
        }
        return true;
      });
      expect(foundGhostText, isTrue);
    });

    testWidgets('renders ghost text inline with existing text', (tester) async {
      controller.text = 'Hello world';
      controller.selection = const TextSelection.collapsed(
        offset: 6,
      ); // After "Hello "
      controller.setGhostText('beautiful ');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(color: Colors.black),
        withComposing: false,
      );

      // Expect "Hello beautiful world" layout
      // Note: "beautiful " is the ghost text.
      expect(span.toPlainText(), 'Hello beautiful world');

      bool foundGhostText = false;
      span.visitChildren((child) {
        if (child is TextSpan && child.text == 'beautiful ') {
          foundGhostText = true;
          expect(child.style?.color?.a, closeTo(0.4, 0.01));
          return false;
        }
        return true;
      });
      expect(foundGhostText, isTrue);
    });

    testWidgets('does not render ghost text if selection is not collapsed', (
      tester,
    ) async {
      controller.text = 'Hello world';
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 5,
      ); // Select "Hello"
      controller.setGhostText('suggestion');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(color: Colors.black),
        withComposing: false,
      );

      // Should ONLY contain original text because selection is range
      expect(span.toPlainText(), 'Hello world');
    });

    testWidgets('does not render ghost text if hidden (null/empty)', (
      tester,
    ) async {
      controller.text = 'Hello';
      controller.selection = const TextSelection.collapsed(offset: 5);
      // implicit null ghostText

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(color: Colors.black),
        withComposing: false,
      );

      expect(span.toPlainText(), 'Hello');
    });

    testWidgets('renders ghost text correctly inside markdown structure (bold)', (
      tester,
    ) async {
      // "**He|ll**" -> inject inside bold span
      controller.text = '**Bo**';
      // Rendered: Bold[Bo]
      // Cursor at 4: "**Bo|" -> end of bold span?
      // Wait, let's try inside. "**B|o**" (offset 3)
      // But text content is "**Bo**" raw.
      // Parse result: one Bold node for "**Bo**".
      // TextSpan tree: TextSpan(text: "Bo", style: bold) (if WYSIWYG)
      // Let's assume WYSIWYG mode is default (true).

      controller.text = '**Bo**';
      controller.selection = const TextSelection.collapsed(
        offset: 3,
      ); // inside "Bo"
      controller.setGhostText('old');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final context = tester.element(find.byType(TextField));
      final span = controller.buildTextSpan(
        context: context,
        style: const TextStyle(color: Colors.black),
        withComposing: false,
      );

      // We expect "B" + "old"(ghost) + "o"
      // Ghost text should NOT inherit bold style opacity, but own logic applies opacity to base style.
      // Ghost implementation uses baseStyle passed to buildTextSpan or copies parent?
      // "final ghostStyle = (baseStyle ?? const TextStyle()).copyWith(color: defaultColor.withOpacity(0.4));"
      // So it uses the editor's base style, NOT the surrounding text style (bold).

      // Verification:
      StringBuffer sb = StringBuffer();
      span.visitChildren((child) {
        if (child is TextSpan && child.text != null) {
          sb.write(child.text);
        }
        return true;
      });
      // Logic inside _renderNode might hide the "**" markers if WYSIWYG is on.
      // Offset 3 in "**Bo**" corresponds to between 'B' and 'o'.
      // If markers are hidden, text seen is "Bo".
      // "B" is at what offset?
      // Node: BoldNode start:0 end:6 text:"**Bo**".
      // Children: TextNode start:2 end:4 text:"Bo".
      // If WYSIWYG on, we see "Bo".
      // Ghost: "old". Result visual: "Boldo".
      // Let's check contains 'old'.

      expect(sb.toString(), contains('old'));
    });
  });
}
