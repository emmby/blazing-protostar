import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_toolbar.dart';

/// A robust Markdown editor widget that supports WYSIWYG editing,
/// toolbar customization, and seamless Yjs integration.
class MarkdownEditor extends StatefulWidget {
  /// The controller that manages the text and markup state.
  final MarkdownTextEditingController controller;

  /// Whether to show the formatting toolbar at the top.
  final bool toolbarVisible;

  /// Whether the editor is read-only.
  final bool readOnly;

  /// Optional focus node.
  final FocusNode? focusNode;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.toolbarVisible = true,
    this.readOnly = false,
    this.focusNode,
  });

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  // We need to listen to the controller to rebuild when isWysiwygMode changes
  // because the toolbar needs to update its state.

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void didUpdateWidget(MarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    // If wysiwyg mode changed, we might need to rebuild toolbar state.
    // For now, simple set state to handle any controller updates that need UI refresh
    // outside of the text field itself (like toolbar toggles)
    setState(() {});
  }

  void _toggleWysiwygMode() {
    setState(() {
      widget.controller.isWysiwygMode = !widget.controller.isWysiwygMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.toolbarVisible)
          MarkdownToolbar(
            controller: widget.controller,
            isWysiwygMode: widget.controller.isWysiwygMode,
            onWysiwygToggle: _toggleWysiwygMode,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              readOnly: widget.readOnly,
              maxLines: null,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Start writing...',
              ),
              // We might want to expose more configuration here later
            ),
          ),
        ),
      ],
    );
  }
}
