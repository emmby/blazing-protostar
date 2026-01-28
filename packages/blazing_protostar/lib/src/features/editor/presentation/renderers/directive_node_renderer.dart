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
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
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
