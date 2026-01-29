import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Base class for all node renderers.
///
/// Uses the Template Method pattern to dispatch between WYSIWYG and Raw modes.
/// Subclasses implement [renderWysiwyg] and [renderRaw] instead of [render].
abstract class BaseNodeRenderer {
  const BaseNodeRenderer();

  /// Main entry point - dispatches to appropriate mode based on WYSIWYG state.
  ///
  /// This is a template method that calls either [renderWysiwyg] or [renderRaw]
  /// based on the mode and reveal state.
  ///
  /// **WARNING: You MUST preserve character count.**
  /// The total length of the returned span (plus any hidden markers)
  /// must equal `expectedLength` (which is `node.end - node.start`).
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    int expectedLength,
    RenderContext renderContext, {
    Node? parent,
  }) {
    if (renderContext.isWysiwygMode && !isRevealed) {
      return renderWysiwyg(
        context,
        node,
        style,
        expectedLength,
        renderContext,
        parent: parent,
      );
    } else {
      return renderRaw(
        context,
        node,
        style,
        expectedLength,
        renderContext,
        parent: parent,
      );
    }
  }

  /// Render in WYSIWYG mode (control characters hidden).
  ///
  /// Called when WYSIWYG mode is enabled and the node is not revealed
  /// (cursor not near this node).
  ///
  /// **WARNING: You MUST preserve character count.**
  /// The total length of the returned span (plus any hidden markers)
  /// must equal `expectedLength` (which is `node.end - node.start`).
  InlineSpan renderWysiwyg(
    BuildContext context,
    Node node,
    TextStyle style,
    int expectedLength,
    RenderContext renderContext, {
    Node? parent,
  });

  /// Render in raw mode (control characters visible in grey).
  ///
  /// Called when WYSIWYG mode is disabled OR the node is revealed
  /// (cursor near this node in Edit mode).
  ///
  /// **WARNING: You MUST preserve character count.**
  /// The total length of the returned span must equal `expectedLength` (which is `node.end - node.start`).
  InlineSpan renderRaw(
    BuildContext context,
    Node node,
    TextStyle style,
    int expectedLength,
    RenderContext renderContext, {
    Node? parent,
  });

  /// The expected character count for this [node].
  ///
  /// Calculated as `node.end - node.start`. Your renderer output must
  /// have an [InlineSpan] tree with this total logical length.
  int nodeLength(Node node) => node.end - node.start;

  /// Helper: Renders control characters (gap text) appropriately for the mode.
  ///
  /// - In WYSIWYG mode: zero-width invisible rendering
  /// - In raw mode: visible grey text
  TextSpan renderControlChars(String text, TextStyle style, bool isWysiwyg) {
    if (isWysiwyg) {
      return TextSpan(
        text: text,
        style: style.copyWith(
          fontSize: 0,
          color: Colors.transparent,
          letterSpacing: 0,
          wordSpacing: 0,
          height: 0,
        ),
      );
    } else {
      return TextSpan(
        text: text,
        style: style.copyWith(color: Colors.grey),
      );
    }
  }
}
