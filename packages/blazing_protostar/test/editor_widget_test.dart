import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  testWidgets('MarkdownTextEditingController renders styling', (tester) async {
    final controller = MarkdownTextEditingController(text: 'Hello **Bold**');

    // Build context provider?
    // buildTextSpan needs a BuildContext, but does not use it in our implementation.
    // We can just call buildTextSpan directly with a dummy context if needed,
    // or verify via a TextField widget.

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller)),
      ),
    );

    // Verify the Controller's internal state directly?
    // We want to check the produced TextSpan. (The one used by the EditableText).

    // Easier Unit Test style:
    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );

    // Expect: TextSpan(children: [
    //   TextSpan("Hello "),
    //   TextSpan("**", color: grey),
    //   TextSpan("Bold", bold),
    //   TextSpan("**", color: grey)
    // ])

    expect(span, isA<TextSpan>());
    final children = span.children!;

    // Correct Hierarchy Expectation:
    // Root Span (Document) -> [Paragraph Span]
    // Paragraph Span -> [TextSpan("Hello "), TextSpan("**"), TextSpan("Bold"), TextSpan("**")]

    // Check Root
    expect(children.length, 1);

    // Check Paragraph
    final paragraphSpan = children[0] as TextSpan;
    final pChildren = paragraphSpan.children!;

    // Correct Hierarchy:
    // Paragraph -> [TextSpan("Hello "), TextSpan(children: ["**", Bold, "**"])]

    // "Hello "
    expect((pChildren[0] as TextSpan).text, 'Hello ');

    // Bold Wrapper
    final boldWrapper = pChildren[1] as TextSpan;
    final boldChildren = boldWrapper.children!;
    expect(boldChildren.length, 3);

    // 1. Opening Syntax "**"
    expect((boldChildren[0] as TextSpan).text, '**');
    expect((boldChildren[0] as TextSpan).style?.color, Colors.grey);

    // 2. Content "Bold"
    expect((boldChildren[1] as TextSpan).text, 'Bold');
    expect((boldChildren[1] as TextSpan).style?.fontWeight, FontWeight.bold);

    // 3. Closing Syntax "**"
    expect((boldChildren[2] as TextSpan).text, '**');
    expect((boldChildren[2] as TextSpan).style?.color, Colors.grey);
  });

  testWidgets('Controller updates activeStyles on selection change', (
    tester,
  ) async {
    final controller = MarkdownTextEditingController(
      text: 'Hello **Bold** world',
    );

    // Simulate selection change: "Hello " (index 2)
    controller.selection = const TextSelection.collapsed(offset: 2);
    expect(controller.activeStyles.value, isEmpty);

    // Simulate selection change: "**Bold**" (index 8, inside Bold)
    // "Hello **" is 8 chars.
    // "Hello **B" is 9.
    // Offset 9 should be inside Bold.
    controller.selection = const TextSelection.collapsed(offset: 9);

    // We need to trigger a build/parse first?
    // The controller parses on buildTextSpan.
    // In a real app, the widget calls buildTextSpan.
    // Here we must mimic that cycle or manually force a parse if the test doesn't pump a widget.
    //
    // The `_updateActiveStyles` listener checks `_lastParsedDocument`.
    // `_lastParsedDocument` is set in `buildTextSpan`.
    // So we MUST call buildTextSpan at least once.

    // Pump widget to ensure Controller is attached and built
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller)),
      ),
    );

    // Move cursor to 2 (Plain)
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump(); // Allow listeners to fire

    expect(controller.activeStyles.value, isEmpty);

    // Move cursor to 9 (Bold)
    controller.selection = const TextSelection.collapsed(offset: 9);
    await tester.pump();

    expect(controller.activeStyles.value.contains('bold'), isTrue);

    // Move cursor to 16 (Plain " world")
    // "Hello **Bold**" -> 6 + 2 + 4 + 2 = 14.
    // " w" -> 16.
    controller.selection = const TextSelection.collapsed(offset: 16);
    await tester.pump();

    expect(controller.activeStyles.value, isEmpty);
  });

  testWidgets('Controller applies formatting correctly', (tester) async {
    final controller = MarkdownTextEditingController(text: 'Hello world');

    // 1. Inline Insert (Bold) - "Hello |world"
    controller.selection = const TextSelection.collapsed(offset: 6);
    controller.applyFormat('bold');
    // "Hello ".length is 6.
    // "Hello " + "**" + "**" + "world" -> "Hello ****world"
    // My expectation string is wrong.

    expect(controller.text, 'Hello ****world');
    expect(controller.selection.baseOffset, 8); // 6 + 2

    // 2. Inline Wrap (Italic) - Select "Hello"
    controller.text = 'Hello world';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    controller.applyFormat('italic');
    expect(controller.text, '_Hello_ world');

    // 3. Block Prefix (Header) - "Hello world"
    controller.text = 'Hello world';
    controller.selection = const TextSelection.collapsed(offset: 5); // Middle
    controller.applyFormat('header');
    expect(controller.text, '# Hello world');

    // 4. Link Insert (Collapsed) - "Link |"
    controller.text = 'Link ';
    controller.selection = const TextSelection.collapsed(offset: 5);
    controller.applyFormat('link');
    expect(controller.text, 'Link [text](url)');
    // Selection should cover "text"
    expect(controller.selection.baseOffset, 6);
    expect(controller.selection.extentOffset, 10);
    expect(controller.selection.textInside(controller.text), 'text');
  });

  testWidgets('Pasting multiline markdown renders all styles', (tester) async {
    final controller = MarkdownTextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller)),
      ),
    );

    // Simulate Paste
    const complexMarkdown =
        '# Header\n'
        'Text with **bold** and [link](url)';
    controller.text = complexMarkdown;
    await tester.pump();

    final span = controller.buildTextSpan(
      context: tester.element(find.byType(TextField)),
      withComposing: false,
    );

    // Verify tree structure
    // Document -> [Header, Gap(\n), Paragraph]
    expect(span.children!.length, 3);

    final headerSpan = span.children![0] as TextSpan;
    expect(
      (headerSpan.children![0] as TextSpan).style?.fontWeight,
      FontWeight.bold,
    ); // Level 1 header
    expect((headerSpan.children![0] as TextSpan).text, '# Header');

    final paragraphSpan = span.children![2] as TextSpan;
    // Newline + Text + Bold + Text + Link
    // Wait, our parser treats Paragraphs as children of Document.
    // The first child of Paragraph is often the leading newline or text.

    // Total components in paragraph:
    // 1. "\nText with " (Gap after header)
    // 2. Bold (children: **, bold, **)
    // 3. " and "
    // 4. Link (children: [, link, ], (, url, ))

    final pChildren = paragraphSpan.children!;
    expect(pChildren.any((s) => s.toPlainText().contains('bold')), isTrue);
    expect(pChildren.any((s) => s.toPlainText().contains('link')), isTrue);

    // Find the BoldNode (which is a TextSpan wrapping children)
    final boldSpan =
        pChildren.firstWhere((s) => s.toPlainText() == '**bold**') as TextSpan;
    expect(
      (boldSpan.children![1] as TextSpan).style?.fontWeight,
      FontWeight.bold,
    );

    // Find the LinkNode
    final linkSpan =
        pChildren.firstWhere((s) => s.toPlainText().contains('[link]'))
            as TextSpan;
    expect(
      (linkSpan.children![1] as TextSpan).style?.color,
      Colors.blue,
    ); // link color
  });

  group('WYSIWYG Mode', () {
    testWidgets('renders control characters with zero-width when enabled', (
      tester,
    ) async {
      final controller = MarkdownTextEditingController(
        text: 'Hello **Bold**',
        isWysiwygMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      // In WYSIWYG mode, control characters (**) should be zero-width
      // Check that we find spans with fontSize near 0 and transparent color
      bool foundZeroWidthSpan = false;
      void checkSpan(InlineSpan s) {
        if (s is TextSpan) {
          if (s.text == '**' &&
              s.style?.fontSize == 0 &&
              s.style?.color == Colors.transparent) {
            foundZeroWidthSpan = true;
          }
          s.children?.forEach(checkSpan);
        }
      }

      span.children?.forEach(checkSpan);

      expect(foundZeroWidthSpan, isTrue);
    });

    testWidgets('shows control characters when disabled', (tester) async {
      final controller = MarkdownTextEditingController(
        text: 'Hello **Bold**',
        isWysiwygMode: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      // In normal mode, control characters should be visible
      final plainText = span.toPlainText();
      expect(plainText, 'Hello **Bold**');
    });

    testWidgets('preserves styling in WYSIWYG mode', (tester) async {
      final controller = MarkdownTextEditingController(
        text: 'Hello **Bold**',
        isWysiwygMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      // Find the bold text span and verify it has bold styling
      bool foundBoldStyle = false;
      void checkSpan(InlineSpan s) {
        if (s is TextSpan) {
          if (s.text == 'Bold' && s.style?.fontWeight == FontWeight.bold) {
            foundBoldStyle = true;
          }
          s.children?.forEach(checkSpan);
        }
      }

      span.children?.forEach(checkSpan);

      expect(foundBoldStyle, isTrue);
    });

    testWidgets('hides header markers in WYSIWYG mode', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '# Header',
        isWysiwygMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      bool foundHiddenMarker = false;
      void checkSpan(InlineSpan s) {
        if (s is TextSpan) {
          if (s.text == '# ' &&
              s.style?.fontSize == 0 &&
              s.style?.color == Colors.transparent &&
              s.style?.letterSpacing == 0) {
            foundHiddenMarker = true;
          }
          s.children?.forEach(checkSpan);
        }
      }

      span.children?.forEach(checkSpan);

      expect(foundHiddenMarker, isTrue);
    });

    testWidgets('replaces list markers with same-length bullets in WYSIWYG mode', (
      tester,
    ) async {
      final controller = MarkdownTextEditingController(
        text: '- List Item',
        isWysiwygMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      bool foundReplacement = false;
      void checkSpan(InlineSpan s) {
        if (s is TextSpan) {
          // Verify we found the replaced string "• "
          if (s.text == '• ') {
            // Verify it is NOT using zero-width style (since we decided to replace instead of hide)
            if (s.style?.fontSize != 0) {
              foundReplacement = true;
            }
          }
          s.children?.forEach(checkSpan);
        }
      }

      span.children?.forEach(checkSpan);

      expect(
        foundReplacement,
        isTrue,
        reason:
            'Should replace "- " with "• " directly without zero-width styling',
      );
    });

    testWidgets('uses comprehensive zero-width styling for control chars', (
      tester,
    ) async {
      // Test with implicit link which uses generic control char hiding
      final controller = MarkdownTextEditingController(
        text: '[link](url)',
        isWysiwygMode: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(TextField)),
        withComposing: false,
      );

      bool foundCorrectZeroWidth = false;
      void checkSpan(InlineSpan s) {
        if (s is TextSpan) {
          // Check for the hidden part of the link syntax, e.g. "](url)" or "["
          // The gaps are typically rendered separately.
          // Let's check if ANY span has the full set of zero-width properties
          if (s.style?.fontSize == 0 &&
              s.style?.height == 0 &&
              s.style?.letterSpacing == 0 &&
              s.style?.wordSpacing == 0) {
            foundCorrectZeroWidth = true;
          }
          s.children?.forEach(checkSpan);
        }
      }

      span.children?.forEach(checkSpan);

      expect(
        foundCorrectZeroWidth,
        isTrue,
        reason: 'Control chars must use height:0 and spacing:0',
      );
    });

    group('Reveal-on-Proximity', () {
      testWidgets('reveals bold markers when cursor is inside', (tester) async {
        final controller = MarkdownTextEditingController(
          text: '**bold**',
          isWysiwygMode: true,
        );
        // Place cursor inside "bold" (offset 3)
        controller.selection = const TextSelection.collapsed(offset: 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TextField(controller: controller)),
          ),
        );

        final span = controller.buildTextSpan(
          context: tester.element(find.byType(TextField)),
          withComposing: false,
        );

        // Should find visible "**" marker (no zero-width style)
        bool foundVisibleMarker = false;
        void checkSpan(InlineSpan s) {
          if (s is TextSpan) {
            if (s.text == '**' && (s.style?.fontSize ?? 14) > 0) {
              foundVisibleMarker = true;
            }
            s.children?.forEach(checkSpan);
          }
        }

        span.children?.forEach(checkSpan);

        expect(
          foundVisibleMarker,
          isTrue,
          reason: 'Markers should be visible when cursor is inside',
        );
      });

      testWidgets('hides bold markers when cursor is outside', (tester) async {
        final controller = MarkdownTextEditingController(
          text: '**bold** outside',
          isWysiwygMode: true,
        );
        // Place cursor outside (offset 10)
        controller.selection = const TextSelection.collapsed(offset: 10);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TextField(controller: controller)),
          ),
        );

        final span = controller.buildTextSpan(
          context: tester.element(find.byType(TextField)),
          withComposing: false,
        );

        // Should find zero-width "**" marker
        bool foundHiddenMarker = false;
        void checkSpan(InlineSpan s) {
          if (s is TextSpan) {
            if (s.text == '**' && s.style?.fontSize == 0) {
              foundHiddenMarker = true;
            }
            s.children?.forEach(checkSpan);
          }
        }

        span.children?.forEach(checkSpan);

        expect(
          foundHiddenMarker,
          isTrue,
          reason: 'Markers should be hidden when cursor is outside',
        );
      });

      testWidgets('reveals list marker when cursor is on line', (tester) async {
        final controller = MarkdownTextEditingController(
          text: '- item',
          isWysiwygMode: true,
        );
        // Cursor on line
        controller.selection = const TextSelection.collapsed(offset: 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TextField(controller: controller)),
          ),
        );

        final span = controller.buildTextSpan(
          context: tester.element(find.byType(TextField)),
          withComposing: false,
        );

        // Should find raw "- " (no bullet replacement)
        bool foundRawMarker = false;
        void checkSpan(InlineSpan s) {
          if (s is TextSpan) {
            // If revealed, we just render the text node normally
            // The text node starts with "- item"
            // But wait, the controller renders children recursively.
            // If I render the TextNode for "- item", it comes as one string "- item".
            if (s.text?.startsWith('- ') == true) {
              foundRawMarker = true;
            }
            s.children?.forEach(checkSpan);
          }
        }

        span.children?.forEach(checkSpan);

        expect(
          foundRawMarker,
          isTrue,
          reason: 'Should show raw "- " marker when cursor is on line',
        );
      });
    });
  });
}
