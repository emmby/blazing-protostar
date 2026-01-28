import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for TextNode.
///
/// Has special parent-aware logic for list markers and header markers.
class TextNodeRenderer extends BaseNodeRenderer {
  const TextNodeRenderer();

  @override
  InlineSpan renderWysiwyg(
    BuildContext context,
    Node node,
    TextStyle style,
    RenderContext renderContext, {
    Node? parent,
  }) {
    final textNode = node as TextNode;

    // Determine if visual replacement should happen
    // We perform replacement if WYSIWYG is ON AND the parent is NOT revealed
    // Note: RenderContext.isWysiwygMode is already handled by BaseNodeRenderer's dispatch
    bool shouldHideMarkers = true;
    if (parent != null && renderContext.shouldRevealNode(parent)) {
      shouldHideMarkers = false;
    }

    if (shouldHideMarkers) {
      // Case 1: List Items
      if (parent is ListItemNode) {
        final nodeText = textNode.text;
        // Match the list marker at start of text (e.g., "- " or "* " or "+ ")
        final markerMatch = RegExp(r'^([*+-])[ \t]+').firstMatch(nodeText);
        if (markerMatch != null) {
          final markerLength = markerMatch.end;
          final markerText = nodeText.substring(0, markerLength);
          final contentText = nodeText.substring(markerLength);

          // Create a replacement string of exact same length
          // e.g. "- " -> "• "
          // This preserves offsets for cursor navigation
          final replacementText = '•${markerText.substring(1)}';

          return TextSpan(
            children: [
              // Render visible bullet replacement
              TextSpan(
                text: replacementText,
                style: style.copyWith(color: Colors.grey.shade600),
              ),
              // Render remaining content normally
              TextSpan(text: contentText, style: style),
            ],
          );
        }
      }

      // Case 2: Headers
      if (parent is HeaderNode) {
        final nodeText = textNode.text;
        // Match ATX header marker (e.g. "## ")
        final markerMatch = RegExp(r'^(#{1,6})[ \t]+').firstMatch(nodeText);
        if (markerMatch != null) {
          final markerLength = markerMatch.end;
          final markerText = nodeText.substring(0, markerLength);
          final contentText = nodeText.substring(markerLength);

          return TextSpan(
            children: [
              renderControlChars(markerText, style, true),
              TextSpan(text: contentText, style: style),
            ],
          );
        }
      }
    }

    return TextSpan(text: textNode.text, style: style);
  }

  @override
  InlineSpan renderRaw(
    BuildContext context,
    Node node,
    TextStyle style,
    RenderContext renderContext, {
    Node? parent,
  }) {
    final textNode = node as TextNode;
    return TextSpan(text: textNode.text, style: style);
  }
}
