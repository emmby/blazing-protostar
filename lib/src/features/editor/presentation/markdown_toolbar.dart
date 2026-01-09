import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

class MarkdownToolbar extends StatelessWidget {
  final MarkdownTextEditingController controller;

  const MarkdownToolbar({super.key, required this.controller});

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
              _ToolbarButton(
                icon: Icons.title,
                isActive: activeStyles.contains('header'),
                onPressed: () => controller.applyFormat('header'),
                tooltip: 'Header',
              ),
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
