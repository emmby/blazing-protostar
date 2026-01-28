import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Renders generic directive using provided builder', (
    tester,
  ) async {
    final controller = MarkdownTextEditingController(
      text: 'Hello :test[User](123)',
      nodeBuilders: {
        InlineDirectiveNode: (context, node, style, isRevealed) {
          final directive = node as InlineDirectiveNode;
          return WidgetSpan(
            child: Container(
              color: Colors.red,
              padding: const EdgeInsets.all(4),
              child: Text(
                'Directive: ${directive.name} content: ${directive.children.map((c) => (c as TextNode).text).join()}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller, maxLines: null)),
      ),
    );

    // Verify text content is present
    expect(find.textContaining('Hello'), findsOneWidget);

    // Verify directive is rendered as a widget (WidgetSpan)
    // Finding specific widgets inside WidgetSpan can be tricky, but we can look for the text rendered by our builder
    expect(find.text('Directive: test content: User'), findsOneWidget);

    // Cleanup
    controller.dispose();
  });
  testWidgets('Renders default fallback for unhandled directives', (
    tester,
  ) async {
    final controller = MarkdownTextEditingController(
      text: 'Default :fallback[Render]',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(controller: controller, maxLines: null)),
      ),
    );

    // In default WYSIWYG mode, markers are hidden, content is shown.
    // However, default fallback for directives is now "render as written".
    // So we expect the full raw text: ":fallback[Render]"
    expect(find.textContaining('Default :fallback[Render]'), findsOneWidget);
  });
}
