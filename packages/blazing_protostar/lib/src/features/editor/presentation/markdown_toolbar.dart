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
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: controller.activeStyles,
        builder: (context, activeStyles, _) {
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ToolbarButton(
                icon: Icons.format_bold,
                isActive: activeStyles.contains('bold'),
                onPressed: () => controller.applyFormat('bold'),
                tooltip: 'Bold',
              ),
              _ToolbarButton(
                icon: Icons.format_italic,
                isActive: activeStyles.contains('italic'),
                onPressed: () => controller.applyFormat('italic'),
                tooltip: 'Italic',
              ),
              const VerticalDivider(width: 16, indent: 12, endIndent: 12),
              _HeadingDropdown(controller: controller),
              _ToolbarButton(
                icon: Icons.format_list_bulleted,
                isActive: activeStyles.contains('list'),
                onPressed: () => controller.applyFormat('list'),
                tooltip: 'List',
              ),
              const VerticalDivider(width: 16, indent: 12, endIndent: 12),
              _ToolbarButton(
                icon: Icons.link,
                isActive: activeStyles.contains('link'),
                onPressed: () => controller.applyFormat('link'),
                tooltip: 'Link',
              ),
              if (onWysiwygToggle != null) ...[
                const VerticalDivider(width: 16, indent: 12, endIndent: 12),
                _ToolbarButton(
                  icon: Icons.code,
                  isActive: !isWysiwygMode,
                  onPressed: onWysiwygToggle!,
                  tooltip: isWysiwygMode ? 'Show Markdown' : 'Hide Markdown',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final String tooltip;

  const _ToolbarButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.black87,
          size: 20,
        ),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isActive
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

/// Dropdown for selecting heading level (Normal, H1-H6).
class _HeadingDropdown extends StatelessWidget {
  final MarkdownTextEditingController controller;

  const _HeadingDropdown({required this.controller});

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
    // Get current heading level to show in dropdown
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
          (index) =>
              DropdownMenuItem<int>(value: index, child: Text(_labels[index])),
        ),
        onChanged: (value) {
          if (value != null) {
            controller.applyHeadingLevel(value);
          }
        },
      ),
    );
  }
}
