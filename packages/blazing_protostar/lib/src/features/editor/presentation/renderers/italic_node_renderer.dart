import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for ItalicNode.
class ItalicNodeRenderer extends BaseNodeRenderer {
  const ItalicNodeRenderer();

  @override
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final italicNode = node as ElementNode;
    final newStyle = style.copyWith(fontStyle: FontStyle.italic);

    final childrenSpans = <InlineSpan>[];
    int currentPos = italicNode.start;

    for (final child in italicNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        if (renderContext.isWysiwygMode && !isRevealed) {
          // Zero-width rendering for control chars (*)
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
          // Normal mode OR revealed: show control chars in grey
          childrenSpans.add(
            TextSpan(
              text: gapText,
              style: newStyle.copyWith(color: Colors.grey),
            ),
          );
        }
      }

      childrenSpans.add(renderContext.renderChild(child, newStyle, italicNode));
      currentPos = child.end;
    }

    if (currentPos < italicNode.end) {
      final gapText = renderContext.text.substring(currentPos, italicNode.end);
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
        childrenSpans.add(
          TextSpan(
            text: gapText,
            style: newStyle.copyWith(color: Colors.grey),
          ),
        );
      }
    }

    return TextSpan(children: childrenSpans);
  }
}
