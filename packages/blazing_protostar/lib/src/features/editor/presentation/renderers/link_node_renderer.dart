import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for LinkNode.
class LinkNodeRenderer extends BaseNodeRenderer {
  const LinkNodeRenderer();

  @override
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final linkNode = node as ElementNode;
    final newStyle = style.copyWith(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    );

    final childrenSpans = <InlineSpan>[];
    int currentPos = linkNode.start;

    for (final child in linkNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        if (renderContext.isWysiwygMode && !isRevealed) {
          // Zero-width rendering for control chars ([, ], (, ))
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

      childrenSpans.add(renderContext.renderChild(child, newStyle, linkNode));
      currentPos = child.end;
    }

    if (currentPos < linkNode.end) {
      final gapText = renderContext.text.substring(currentPos, linkNode.end);
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
