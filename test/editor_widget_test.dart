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
}
