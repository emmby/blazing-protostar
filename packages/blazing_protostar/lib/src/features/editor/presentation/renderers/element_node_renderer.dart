import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Generic renderer for ElementNode and its subclasses.
///
/// Used for nodes that don't need special styling (Paragraph, List, Document, etc.)
class ElementNodeRenderer extends BaseNodeRenderer {
  const ElementNodeRenderer();

  @override
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final elementNode = node as ElementNode;

    final childrenSpans = <InlineSpan>[];
    int currentPos = elementNode.start;

    for (final child in elementNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        if (renderContext.isWysiwygMode && !isRevealed) {
          // Zero-width rendering for control chars
          childrenSpans.add(
            TextSpan(
              text: gapText,
              style: style.copyWith(
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
              style: style.copyWith(color: Colors.grey),
            ),
          );
        }
      }

      childrenSpans.add(renderContext.renderChild(child, style, elementNode));
      currentPos = child.end;
    }

    if (currentPos < elementNode.end) {
      final gapText = renderContext.text.substring(currentPos, elementNode.end);
      if (renderContext.isWysiwygMode && !isRevealed) {
        childrenSpans.add(
          TextSpan(
            text: gapText,
            style: style.copyWith(
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
            style: style.copyWith(color: Colors.grey),
          ),
        );
      }
    }

    return TextSpan(children: childrenSpans);
  }
}
