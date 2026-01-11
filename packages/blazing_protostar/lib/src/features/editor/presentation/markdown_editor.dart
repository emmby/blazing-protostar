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
  /// Optional focus node.
  final FocusNode? focusNode;

  /// Whether the editor should expand to fill the available space.
  ///
  /// If true, the editor uses an [Expanded] widget to fill the parent.
  /// If false, it sizes itself to its content (plus minLines).
  final bool expands;

  /// The padding around the input field.
  final EdgeInsetsGeometry? padding;

  /// The decoration to show around the text field.
  final InputDecoration? decoration;

  /// The minimum number of lines to show.
  final int? minLines;

  /// The maximum number of lines to show.
  final int? maxLines;

  const MarkdownEditor({
    super.key,
    required this.controller,
    this.toolbarVisible = true,
    this.readOnly = false,
    this.focusNode,
    this.expands = true,
    this.padding,
    this.decoration,
    this.minLines,
    this.maxLines,
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
    // The standard decoration if none is provided
    final effectiveDecoration =
        (widget.decoration ??
                const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Start writing...',
                ))
            .copyWith(
              // We apply padding via contentPadding if it's not expanding,
              // or generally if provided. But usually padding is better around the TextField?
              // Actually, standard is to put padding in contentPadding or wrap in Padding.
              // If we wrap in Padding, we shrink the scrollable area.
              // Let's use Padding widget for simplicity, as it matches "padding around the input".
            );

    Widget editorField = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      maxLines: widget.expands ? null : widget.maxLines,
      minLines: widget.expands ? null : widget.minLines,
      expands: widget.expands,
      decoration: effectiveDecoration,
    );

    // Apply Padding
    editorField = Padding(
      padding: widget.padding ?? const EdgeInsets.all(16.0),
      child: editorField,
    );

    if (widget.expands) {
      editorField = Expanded(child: editorField);
    }

    return Column(
      mainAxisSize: widget.expands ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.toolbarVisible)
          MarkdownToolbar(
            controller: widget.controller,
            isWysiwygMode: widget.controller.isWysiwygMode,
            onWysiwygToggle: _toggleWysiwygMode,
          ),
        editorField,
      ],
    );
  }
}
