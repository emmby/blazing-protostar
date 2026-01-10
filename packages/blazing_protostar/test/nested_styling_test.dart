import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  group('Comprehensive Nested Styling', () {
    // Helper to extract styles
    TextStyle? getStyle(InlineSpan span, String text) {
      if (span is TextSpan) {
        if (span.text == text) return span.style;
        if (span.children != null) {
          for (final child in span.children!) {
            final style = getStyle(child, text);
            if (style != null) return style;
          }
        }
      }
      return null;
    }

    testWidgets('Header > Bold', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '# **HeaderBold**',
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

      final style = getStyle(span, 'HeaderBold');
      expect(style?.fontWeight, FontWeight.bold, reason: 'Header > Bold');
    });

    testWidgets('Header > Italic', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '# *HeaderItalic*',
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

      final style = getStyle(span, 'HeaderItalic');
      expect(style?.fontStyle, FontStyle.italic, reason: 'Header > Italic');
    });

    testWidgets('Header > Link', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '# [HeaderLink](url)',
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

      final style = getStyle(span, 'HeaderLink');
      expect(style?.color, Colors.blue, reason: 'Header > Link');
    });

    testWidgets('List > Bold', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '- **ListBold**',
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

      final style = getStyle(span, 'ListBold');
      expect(style?.fontWeight, FontWeight.bold, reason: 'List > Bold');
    });

    testWidgets('List > Italic', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '- *ListItalic*',
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

      final style = getStyle(span, 'ListItalic');
      expect(style?.fontStyle, FontStyle.italic, reason: 'List > Italic');
    });

    testWidgets('List > Link', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '- [ListLink](url)',
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

      final style = getStyle(span, 'ListLink');
      expect(style?.color, Colors.blue, reason: 'List > Link');
    });

    testWidgets('Bold > Italic', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '**_BoldItalic_**',
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

      final style = getStyle(span, 'BoldItalic');
      expect(
        style?.fontWeight,
        FontWeight.bold,
        reason: 'Bold should be applied',
      );
      expect(
        style?.fontStyle,
        FontStyle.italic,
        reason: 'Italic should be applied inside Bold',
      );
    });

    testWidgets('Italic > Bold', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '_**ItalicBold**_',
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

      final style = getStyle(span, 'ItalicBold');
      expect(
        style?.fontWeight,
        FontWeight.bold,
        reason: 'Bold should be applied inside Italic',
      );
      expect(
        style?.fontStyle,
        FontStyle.italic,
        reason: 'Italic should be applied',
      );
    });

    testWidgets('Link > Bold', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '[**LinkBold**](url)',
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

      final style = getStyle(span, 'LinkBold');
      expect(style?.color, Colors.blue, reason: 'Link color should be applied');
      expect(
        style?.fontWeight,
        FontWeight.bold,
        reason: 'Bold should be applied inside Link',
      );
    });

    testWidgets('Bold > Link', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '**[BoldLink](url)**',
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

      final style = getStyle(span, 'BoldLink');
      expect(
        style?.color,
        Colors.blue,
        reason: 'Link color should be applied inside Bold',
      );
      expect(
        style?.fontWeight,
        FontWeight.bold,
        reason: 'Bold should be applied',
      );
    });
  });
}
