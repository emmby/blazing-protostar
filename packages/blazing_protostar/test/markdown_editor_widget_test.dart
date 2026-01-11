import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/blazing_protostar.dart';

void main() {
  testWidgets('MarkdownEditor renders TextField and Toolbar', (tester) async {
    final controller = MarkdownTextEditingController(text: 'Hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MarkdownEditor(controller: controller)),
      ),
    );

    // Verify TextField is present
    expect(find.byType(TextField), findsOneWidget);

    // Verify Toolbar is present (it's internal, but we can find by type if exported or by key properties)
    // Since MarkdownToolbar is exported, we can look for it.
    expect(find.byType(MarkdownToolbar), findsOneWidget);

    // Verify text
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('MarkdownEditor hides toolbar when configured', (tester) async {
    final controller = MarkdownTextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownEditor(controller: controller, toolbarVisible: false),
        ),
      ),
    );

    expect(find.byType(MarkdownToolbar), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
}
