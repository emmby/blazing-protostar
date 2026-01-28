import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for HeaderNode.
class HeaderNodeRenderer extends BaseNodeRenderer {
  const HeaderNodeRenderer();

  @override
  InlineSpan renderWysiwyg(
    BuildContext context,
    Node node,
    TextStyle style,
    RenderContext renderContext, {
    Node? parent,
  }) {
    return _renderWithStyle(node as HeaderNode, style, renderContext, true);
  }

  @override
  InlineSpan renderRaw(
    BuildContext context,
    Node node,
    TextStyle style,
    RenderContext renderContext, {
    Node? parent,
  }) {
    return _renderWithStyle(node as HeaderNode, style, renderContext, false);
  }

  /// Common rendering logic for both modes
  InlineSpan _renderWithStyle(
    HeaderNode header,
    TextStyle style,
    RenderContext renderContext,
    bool isWysiwyg,
  ) {
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
        childrenSpans.add(renderControlChars(gapText, newStyle, isWysiwyg));
      }

      childrenSpans.add(renderContext.renderChild(child, newStyle, header));
      currentPos = child.end;
    }

    if (currentPos < header.end) {
      final gapText = renderContext.text.substring(currentPos, header.end);
      childrenSpans.add(renderControlChars(gapText, newStyle, isWysiwyg));
    }

    return TextSpan(children: childrenSpans);
  }
}
