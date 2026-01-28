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

  testWidgets('MarkdownEditor respects expands: false (Form Mode)', (
    tester,
  ) async {
    final controller = MarkdownTextEditingController(text: 'Line 1\nLine 2');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Header'),
                MarkdownEditor(
                  controller: controller,
                  expands: false, // Should allow scrolling parent
                  maxLines: null, // Grow with content
                  padding: const EdgeInsets.all(8.0),
                ),
                const Text('Footer'),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify it renders without overflow
    expect(find.byType(MarkdownEditor), findsOneWidget);

    // Verify padding is applied
    final paddingWidget = tester.widget<Padding>(
      find
          .ancestor(of: find.byType(TextField), matching: find.byType(Padding))
          .first,
    );
    expect(paddingWidget.padding, const EdgeInsets.all(8.0));
  });

  testWidgets('MarkdownEditor uses custom toolbarBuilder', (tester) async {
    final controller = MarkdownTextEditingController(text: 'Test');
    bool customButtonPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownEditor(
            controller: controller,
            toolbarBuilder: (context, ctrl, isWysiwyg, onToggle) {
              return Container(
                key: const Key('custom-toolbar'),
                child: IconButton(
                  key: const Key('custom-button'),
                  icon: const Icon(Icons.star),
                  onPressed: () => customButtonPressed = true,
                ),
              );
            },
          ),
        ),
      ),
    );

    // Verify custom toolbar is rendered
    expect(find.byKey(const Key('custom-toolbar')), findsOneWidget);
    expect(find.byKey(const Key('custom-button')), findsOneWidget);

    // Verify default toolbar is NOT rendered
    expect(find.byType(MarkdownToolbar), findsNothing);

    // Verify custom button works
    await tester.tap(find.byKey(const Key('custom-button')));
    expect(customButtonPressed, true);
  });
}
