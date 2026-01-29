import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/base_node_renderer.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/widgets.dart';

/// Renderer for InlineDirectiveNode.
///
/// By default, renders directives as raw text (opt-in behavior).
/// Users can override this to render custom widgets.
class DirectiveNodeRenderer extends BaseNodeRenderer {
  const DirectiveNodeRenderer();

  @override
  InlineSpan renderWysiwyg(
    BuildContext context,
    Node node,
    TextStyle style,
    int expectedLength,
    RenderContext renderContext, {
    Node? parent,
  }) {
    // Both modes render the same way - as raw text
    return _renderAsRawText(node, style, renderContext);
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
    // Both modes render the same way - as raw text
    return _renderAsRawText(node, style, renderContext);
  }

  /// Renders directive as raw text (default behavior)
  InlineSpan _renderAsRawText(
    Node node,
    TextStyle style,
    RenderContext renderContext,
  ) {
    final directive = node as InlineDirectiveNode;

    // Render directives as raw text by default (opt-in behavior via custom renderers)
    return TextSpan(
      text: renderContext.text.substring(directive.start, directive.end),
      style: style,
    );
  }
}
