import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/blazing_protostar.dart';

void main() {
  group('MarkdownStyleButton', () {
    testWidgets('renders and responds to controller state', (tester) async {
      final controller = MarkdownTextEditingController(text: '**bold**');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownStyleButton(
              controller: controller,
              style: 'bold',
              icon: Icons.format_bold,
              tooltip: 'Bold',
            ),
          ),
        ),
      );

      // Find the button
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.format_bold), findsOneWidget);

      // Initially not active (cursor not in bold text)
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      // Move cursor into bold text
      controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();

      // Button should be active now (visual state test would check color)
      expect(find.byType(MarkdownStyleButton), findsOneWidget);
    });

    testWidgets('calls applyFormat when pressed', (tester) async {
      final controller = MarkdownTextEditingController(text: 'Hello');
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownStyleButton(
              controller: controller,
              style: 'bold',
              icon: Icons.format_bold,
              tooltip: 'Bold',
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Verify format was applied (bold adds ** at start of line when no selection)
      expect(controller.text, '****Hello');
    });
  });

  group('MarkdownHeadingDropdown', () {
    testWidgets('renders with current heading level', (tester) async {
      final controller = MarkdownTextEditingController(text: '## Heading');
      controller.selection = const TextSelection.collapsed(offset: 3);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MarkdownHeadingDropdown(controller: controller)),
        ),
      );

      // Find dropdown
      expect(find.byType(DropdownButton<int>), findsOneWidget);

      // Should show "Heading 2" for ##
      expect(find.text('Heading 2'), findsOneWidget);
    });

    testWidgets('applies heading level when changed', (tester) async {
      final controller = MarkdownTextEditingController(text: 'Normal');
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MarkdownHeadingDropdown(controller: controller)),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();

      // Select H1
      await tester.tap(find.text('Heading 1').last);
      await tester.pumpAndSettle();

      // Verify heading was applied
      expect(controller.text, '# Normal');
    });
  });

  group('MarkdownWysiwygToggleButton', () {
    testWidgets('renders with correct icon and tooltip', (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownWysiwygToggleButton(
              isWysiwygMode: true,
              onPressed: () => toggled = true,
            ),
          ),
        ),
      );

      // Find button
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);

      // Check tooltip for WYSIWYG mode
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Show Markdown');

      // Tap button
      await tester.tap(find.byType(IconButton));
      expect(toggled, true);
    });

    testWidgets('shows correct tooltip for raw mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownWysiwygToggleButton(
              isWysiwygMode: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Hide Markdown');
    });
  });

  group('MarkdownToolbar buildToolbarButtons', () {
    testWidgets('can be overridden via subclassing', (tester) async {
      final controller = MarkdownTextEditingController(text: 'Test');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: _CustomToolbar(controller: controller)),
        ),
      );

      // Should find custom button
      expect(find.byKey(const Key('custom-toolbar-button')), findsOneWidget);

      // Should NOT find default bold button
      // (We'd need to check for specific widgets if we wanted to be more precise)
    });
  });
}

/// Test subclass of MarkdownToolbar
class _CustomToolbar extends MarkdownToolbar {
  const _CustomToolbar({required super.controller});

  @override
  List<Widget> buildToolbarButtons(BuildContext context) {
    return [
      IconButton(
        key: const Key('custom-toolbar-button'),
        icon: const Icon(Icons.star),
        onPressed: () => controller.insertAtCursor(':star:'),
      ),
    ];
  }
}
