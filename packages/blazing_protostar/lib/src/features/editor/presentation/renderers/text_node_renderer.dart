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
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final textNode = node as TextNode;

    // Note: isRevealed is for the TextNode itself, but we need parent reveal state
    // This is handled through the parent parameter in the dispatch logic

    return TextSpan(text: textNode.text, style: style);
  }

  /// Special rendering logic for TextNode that depends on parent type.
  /// This is called separately by the controller's dispatch logic.
  InlineSpan renderWithParent(
    TextNode node,
    TextStyle style,
    Node? parent,
    RenderContext renderContext,
  ) {
    // Determine if visual replacement should happen
    // We perform replacement if WYSIWYG is ON AND the parent is NOT revealed
    bool shouldHideMarkers = renderContext.isWysiwygMode;
    if (parent != null && renderContext.shouldRevealNode(parent)) {
      shouldHideMarkers = false;
    }

    if (shouldHideMarkers) {
      // Case 1: List Items
      if (parent is ListItemNode) {
        final nodeText = node.text;
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
        final nodeText = node.text;
        // Match ATX header marker (e.g. "## ")
        final markerMatch = RegExp(r'^(#{1,6})[ \t]+').firstMatch(nodeText);
        if (markerMatch != null) {
          final markerLength = markerMatch.end;
          final markerText = nodeText.substring(0, markerLength);
          final contentText = nodeText.substring(markerLength);

          return TextSpan(
            children: [
              TextSpan(
                text: markerText,
                style: style.copyWith(
                  fontSize: 0,
                  color: Colors.transparent,
                  letterSpacing: 0,
                  wordSpacing: 0,
                  height: 0,
                ),
              ),
              TextSpan(text: contentText, style: style),
            ],
          );
        }
      }
    }

    return TextSpan(text: node.text, style: style);
  }
}
