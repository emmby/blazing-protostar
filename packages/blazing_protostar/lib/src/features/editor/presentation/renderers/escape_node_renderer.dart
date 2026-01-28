import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for EscapeNode.
class EscapeNodeRenderer extends BaseNodeRenderer {
  const EscapeNodeRenderer();

  @override
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final escapeNode = node as ElementNode;
    final newStyle = style.copyWith(color: Colors.grey);

    final childrenSpans = <InlineSpan>[];
    int currentPos = escapeNode.start;

    for (final child in escapeNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        if (renderContext.isWysiwygMode && !isRevealed) {
          // Zero-width rendering for backslash
          childrenSpans.add(
            TextSpan(
              text: gapText,
              style: newStyle.copyWith(
                fontSize: 0,
                color: Colors.transparent,
                letterSpacing: 0,
                wordSpacing: 0,
                height: 0,
              ),
            ),
          );
        } else {
          // Normal mode OR revealed: show backslash in grey
          childrenSpans.add(TextSpan(text: gapText, style: newStyle));
        }
      }

      childrenSpans.add(renderContext.renderChild(child, newStyle, escapeNode));
      currentPos = child.end;
    }

    if (currentPos < escapeNode.end) {
      final gapText = renderContext.text.substring(currentPos, escapeNode.end);
      if (renderContext.isWysiwygMode && !isRevealed) {
        childrenSpans.add(
          TextSpan(
            text: gapText,
            style: newStyle.copyWith(
              fontSize: 0,
              color: Colors.transparent,
              letterSpacing: 0,
              wordSpacing: 0,
              height: 0,
            ),
          ),
        );
      } else {
        childrenSpans.add(TextSpan(text: gapText, style: newStyle));
      }
    }

    return TextSpan(children: childrenSpans);
  }
}
