import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for BoldNode.
class BoldNodeRenderer extends BaseNodeRenderer {
  const BoldNodeRenderer();

  @override
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final boldNode = node as ElementNode;
    final newStyle = style.copyWith(fontWeight: FontWeight.bold);

    final childrenSpans = <InlineSpan>[];
    int currentPos = boldNode.start;

    for (final child in boldNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        if (renderContext.isWysiwygMode && !isRevealed) {
          // Zero-width rendering for control chars (**)
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

      childrenSpans.add(renderContext.renderChild(child, newStyle, boldNode));
      currentPos = child.end;
    }

    if (currentPos < boldNode.end) {
      final gapText = renderContext.text.substring(currentPos, boldNode.end);
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
