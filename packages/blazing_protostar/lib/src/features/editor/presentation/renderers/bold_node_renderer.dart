import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for BoldNode.
class BoldNodeRenderer extends BaseNodeRenderer {
  const BoldNodeRenderer();

  @override
  InlineSpan renderWysiwyg(
    BuildContext context,
    Node node,
    TextStyle style,
    int expectedLength,
    RenderContext renderContext, {
    Node? parent,
  }) {
    return _renderWithStyle(node as ElementNode, style, renderContext, true);
  }

  @override
  InlineSpan renderRaw(
    BuildContext context,
    Node node,
    TextStyle style,
    int expectedLength,
    RenderContext renderContext, {
    Node? parent,
  }) {
    return _renderWithStyle(node as ElementNode, style, renderContext, false);
  }

  /// Common rendering logic for both modes
  InlineSpan _renderWithStyle(
    ElementNode boldNode,
    TextStyle style,
    RenderContext renderContext,
    bool isWysiwyg,
  ) {
    final newStyle = style.copyWith(fontWeight: FontWeight.bold);
    final childrenSpans = <InlineSpan>[];
    int currentPos = boldNode.start;

    for (final child in boldNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        childrenSpans.add(renderControlChars(gapText, newStyle, isWysiwyg));
      }

      childrenSpans.add(renderContext.renderChild(child, newStyle, boldNode));
      currentPos = child.end;
    }

    if (currentPos < boldNode.end) {
      final gapText = renderContext.text.substring(currentPos, boldNode.end);
      childrenSpans.add(renderControlChars(gapText, newStyle, isWysiwyg));
    }

    return TextSpan(children: childrenSpans);
  }
}
