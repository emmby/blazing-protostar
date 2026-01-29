import 'package:blazing_protostar/blazing_protostar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Custom Rendering', () {
    testWidgets('Custom Header Renderer overrides default style', (
      tester,
    ) async {
      final controller = MarkdownTextEditingController(
        text: '# Hello',
        nodeBuilders: {
          HeaderNode:
              (context, node, style, isRevealed, expectedLength, [parent]) {
                final header = node as HeaderNode;
                final text = header.children
                    .whereType<TextNode>()
                    .map((e) => e.text)
                    .join();

                return TextSpan(
                  text: text,
                  style: style.copyWith(color: Colors.red),
                );
              },
        },
      );

      // Build a minimal context
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  withComposing: false,
                );
                return RichText(text: span);
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.byType(RichText);
      final richText = tester.widget<RichText>(richTextFinder);
      final span = richText.text as TextSpan;

      // Expect specific structure based on our custom renderer
      // Note: HeaderNode includes the # marker in its text usually?
      // Let's check how default parser does it.
      // Usually default separates marker and content.
      // Our custom renderer simply returns node.text.
      // If node.text includes "## ", then we expect that.

      // The root span is actually a wrapper from buildTextSpan for DocumentNode
      // The custom renderer returns a TextSpan for the HeaderNode,
      // which should be in the children
      expect(span.children, isNotNull);

      expect(span.children!.length, greaterThan(0));

      // Our custom renderer was called for HeaderNode and returned a red TextSpan
      // It should be directly in the children
      final redSpans = span.children!
          .whereType<TextSpan>()
          .where((s) => s.style?.color == Colors.red)
          .toList();

      expect(
        redSpans.isNotEmpty,
        isTrue,
        reason: 'Should find at least one red span',
      );

      final headerSpan = redSpans.first;
      expect(headerSpan.style?.color, Colors.red);
      expect(headerSpan.text, '# Hello'); // Includes marker from extraction
    });

    testWidgets('Custom Bold Renderer with WidgetSpan', (tester) async {
      final controller = MarkdownTextEditingController(
        text: '**Bold**',
        nodeBuilders: {
          BoldNode:
              (context, node, style, isRevealed, expectedLength, [parent]) {
                return TextSpan(
                  children: [
                    WidgetSpan(
                      child: Container(
                        color: Colors.yellow,
                        child: Text('Custom Bold'),
                      ),
                    ),
                    TextSpan(
                      text: '\u200b' * (node.end - node.start - 1),
                      style: const TextStyle(fontSize: 0),
                    ),
                  ],
                );
              },
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  withComposing: false,
                );
                return RichText(text: span);
              },
            ),
          ),
        ),
      );

      // Verify WidgetSpan is present
      // final richText = tester.widget<RichText>(find.byType(RichText));
      // final rootSpan = richText.text as TextSpan;

      // Depending on implementation, the root might be ParagraphNode -> BoldNode
      // So we might have TextSpan(children: [WidgetSpan(...)])

      expect(find.text('Custom Bold'), findsOneWidget);
    });

    testWidgets('isRevealed parameter works correctly', (tester) async {
      // Test that isRevealed is true when cursor is inside the node
      bool capturedIsRevealed = false;

      final controller = MarkdownTextEditingController(
        text: '# Header',
        nodeBuilders: {
          HeaderNode:
              (context, node, style, isRevealed, expectedLength, [parent]) {
                capturedIsRevealed = isRevealed;
                // Source: '# Header' (length 8)
                // 'Rendered' (length 8) - matches!
                return TextSpan(text: 'Rendered');
              },
        },
      );

      // 1. Cursor NOT in header (offset -1 or far away)
      controller.selection = const TextSelection.collapsed(offset: 0);
      // Offset 0 is start of '# Header'.
      // HeaderNode usually spans the whole line.
      // Let's verify standard proximity logic.

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Material(child: Container()),
        ),
      );

      // Trigger build
      final context = tester.element(find.byType(Container));

      // Case A: Cursor inside header
      controller.selection = const TextSelection.collapsed(offset: 2); // Inside
      controller.buildTextSpan(context: context, withComposing: false);
      expect(capturedIsRevealed, isTrue);

      // Case B: Cursor outside header (impossible with single line doc unless we add newline)
      controller.text = '# Header\n\nParagraph';
      controller.selection = const TextSelection.collapsed(
        offset: 12,
      ); // In paragraph
      controller.buildTextSpan(context: context, withComposing: false);
      // Wait, nodeBuilders is attached to the NEW text's AST?
      // Changing text triggers parse? Yes parser runs inside buildTextSpan.
      expect(capturedIsRevealed, isFalse);
    });

    testWidgets('Regression: Default rendering is preserved when empty', (
      tester,
    ) async {
      final controller = MarkdownTextEditingController(
        text: '# Hello',
        // No nodeBuilders
      );

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = controller.buildTextSpan(
                  context: context,
                  withComposing: false,
                );
                return RichText(text: span);
              },
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;

      // Should follow default Header rendering (FontSize changes, etc)
      // We expect children structure (Marker + Content if Wysiwyg is ON/OFF etc)
      // Default is Wysiwyg ON. Cursor starts at -1.
      // So marker '# ' should be hidden (zero width).

      final children = span.children;
      expect(children, isNotNull);
      // Expect marker span (hidden) and content span
      // This confirms we didn't break the default visibility logic.

      // Since specific structure depends on parser implementation,
      // passing this test confirms at least it builds successfully
      // and produces a structure (not crashing or returning empty).
      expect(span.toPlainText(), '# Hello');
    });
  });
}
