import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for ItalicNode.
class ItalicNodeRenderer extends BaseNodeRenderer {
  const ItalicNodeRenderer();

  @override
  InlineSpan renderWysiwyg(
    BuildContext context,
    Node node,
    TextStyle style,
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
    RenderContext renderContext, {
    Node? parent,
  }) {
    return _renderWithStyle(node as ElementNode, style, renderContext, false);
  }

  /// Common rendering logic for both modes
  InlineSpan _renderWithStyle(
    ElementNode italicNode,
    TextStyle style,
    RenderContext renderContext,
    bool isWysiwyg,
  ) {
    final newStyle = style.copyWith(fontStyle: FontStyle.italic);
    final childrenSpans = <InlineSpan>[];
    int currentPos = italicNode.start;

    for (final child in italicNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        childrenSpans.add(renderControlChars(gapText, newStyle, isWysiwyg));
      }

      childrenSpans.add(renderContext.renderChild(child, newStyle, italicNode));
      currentPos = child.end;
    }

    if (currentPos < italicNode.end) {
      final gapText = renderContext.text.substring(currentPos, italicNode.end);
      childrenSpans.add(renderControlChars(gapText, newStyle, isWysiwyg));
    }

    return TextSpan(children: childrenSpans);
  }
}
