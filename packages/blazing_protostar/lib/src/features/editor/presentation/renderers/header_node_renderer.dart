import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for HeaderNode.
class HeaderNodeRenderer extends BaseNodeRenderer {
  const HeaderNodeRenderer();

  @override
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  ) {
    final header = node as HeaderNode;

    // Calculate header style based on level
    double size;
    switch (header.level) {
      case 1:
        size = 32.0;
        break;
      case 2:
        size = 26.0;
        break;
      case 3:
        size = 22.0;
        break;
      case 4:
        size = 19.0;
        break;
      case 5:
        size = 16.0;
        break;
      case 6:
      default:
        size = 14.0;
        break;
    }

    final newStyle = style.copyWith(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    // Render children with header style
    final childrenSpans = <InlineSpan>[];
    int currentPos = header.start;

    for (final child in header.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        if (renderContext.isWysiwygMode && !isRevealed) {
          // Zero-width rendering for # markers
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
          // Normal mode OR revealed: show # in grey
          childrenSpans.add(
            TextSpan(
              text: gapText,
              style: newStyle.copyWith(color: Colors.grey),
            ),
          );
        }
      }

      childrenSpans.add(renderContext.renderChild(child, newStyle, header));
      currentPos = child.end;
    }

    if (currentPos < header.end) {
      final gapText = renderContext.text.substring(currentPos, header.end);
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
