import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

class MarkdownToolbar extends StatelessWidget {
  final MarkdownTextEditingController controller;

  /// Whether WYSIWYG mode is currently active.
  final bool isWysiwygMode;

  /// Callback when WYSIWYG toggle is pressed.
  final VoidCallback? onWysiwygToggle;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    this.isWysiwygMode = false,
    this.onWysiwygToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: buildToolbarButtons(context),
      ),
    );
  }

  /// Builds the list of widgets to display in the toolbar.
  /// Override this method to customize the toolbar actions.
  @visibleForTesting
  List<Widget> buildToolbarButtons(BuildContext context) {
    return [
      MarkdownStyleButton(
        controller: controller,
        style: 'bold',
        icon: Icons.format_bold,
        tooltip: 'Bold',
      ),
      MarkdownStyleButton(
        controller: controller,
        style: 'italic',
        icon: Icons.format_italic,
        tooltip: 'Italic',
      ),
      const VerticalDivider(width: 16, indent: 12, endIndent: 12),
      MarkdownHeadingDropdown(controller: controller),
      MarkdownStyleButton(
        controller: controller,
        style: 'list',
        icon: Icons.format_list_bulleted,
        tooltip: 'List',
      ),
      const VerticalDivider(width: 16, indent: 12, endIndent: 12),
      MarkdownStyleButton(
        controller: controller,
        style: 'link',
        icon: Icons.link,
        tooltip: 'Link',
      ),
      if (onWysiwygToggle != null) ...[
        const VerticalDivider(width: 16, indent: 12, endIndent: 12),
        MarkdownWysiwygToggleButton(
          isWysiwygMode: isWysiwygMode,
          onPressed: onWysiwygToggle!,
        ),
      ],
    ];
  }
}

/// A smart button that listens to the controller's active styles to toggle state.
class MarkdownStyleButton extends StatelessWidget {
  final MarkdownTextEditingController controller;
  final String style;
  final IconData icon;
  final String tooltip;

  const MarkdownStyleButton({
    super.key,
    required this.controller,
    required this.style,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.activeStyles,
      builder: (context, activeStyles, _) {
        final isActive = activeStyles.contains(style);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.blue : Colors.black87,
              size: 20,
            ),
            onPressed: () => controller.applyFormat(style),
            tooltip: tooltip,
            style: IconButton.styleFrom(
              backgroundColor: isActive
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dropdown for selecting heading level (Normal, H1-H6).
/// Listens to the controller to update the currently selected level.
class MarkdownHeadingDropdown extends StatelessWidget {
  final MarkdownTextEditingController controller;

  const MarkdownHeadingDropdown({super.key, required this.controller});

  static const List<String> _labels = [
    'Normal',
    'Heading 1',
    'Heading 2',
    'Heading 3',
    'Heading 4',
    'Heading 5',
    'Heading 6',
  ];

  @override
  Widget build(BuildContext context) {
    // Listen to the controller for selection/text changes
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentLevel = controller.getCurrentHeadingLevel();

        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: currentLevel,
            underline: const SizedBox.shrink(),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            items: List.generate(
              _labels.length,
              (index) => DropdownMenuItem<int>(
                value: index,
                child: Text(_labels[index]),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                controller.applyHeadingLevel(value);
              }
            },
          ),
        );
      },
    );
  }
}

/// A button to toggle between WYSIWYG and Raw Markdown modes.
class MarkdownWysiwygToggleButton extends StatelessWidget {
  final bool isWysiwygMode;
  final VoidCallback onPressed;

  const MarkdownWysiwygToggleButton({
    super.key,
    required this.isWysiwygMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: IconButton(
        icon: const Icon(Icons.code, color: Colors.black87, size: 20),
        onPressed: onPressed,
        tooltip: isWysiwygMode ? 'Show Markdown' : 'Hide Markdown',
        style: IconButton.styleFrom(
          backgroundColor: !isWysiwygMode
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
