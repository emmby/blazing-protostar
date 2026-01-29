import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/material.dart';

/// Renderer for ElementNode and its subclasses.
///
/// Used for nodes that don't need special styling (Paragraph, List, Document, etc.)
class ElementNodeRenderer extends BaseNodeRenderer {
  const ElementNodeRenderer();

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
    ElementNode elementNode,
    TextStyle style,
    RenderContext renderContext,
    bool isWysiwyg,
  ) {
    final childrenSpans = <InlineSpan>[];
    int currentPos = elementNode.start;

    for (final child in elementNode.children) {
      if (child.start > currentPos) {
        final gapText = renderContext.text.substring(currentPos, child.start);
        childrenSpans.add(renderControlChars(gapText, style, isWysiwyg));
      }

      childrenSpans.add(renderContext.renderChild(child, style, elementNode));
      currentPos = child.end;
    }

    if (currentPos < elementNode.end) {
      final gapText = renderContext.text.substring(currentPos, elementNode.end);
      childrenSpans.add(renderControlChars(gapText, style, isWysiwyg));
    }

    return TextSpan(children: childrenSpans);
  }
}
