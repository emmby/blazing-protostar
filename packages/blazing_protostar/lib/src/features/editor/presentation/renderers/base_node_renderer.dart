import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/presentation/renderers/render_context.dart';
import 'package:flutter/widgets.dart';

/// Base class for all node renderers.
///
/// Renderers are responsible for converting AST nodes into Flutter InlineSpans.
/// Each node type should have its own renderer implementation.
abstract class BaseNodeRenderer {
  const BaseNodeRenderer();

  /// Renders a node into an InlineSpan.
  ///
  /// - [context]: Build context for widget creation
  /// - [node]: The AST node to render
  /// - [style]: Base text style to apply
  /// - [isRevealed]: Whether cursor is near this node (Edit Mode)
  /// - [renderContext]: Provides access to controller state and recursive rendering
  InlineSpan render(
    BuildContext context,
    Node node,
    TextStyle style,
    bool isRevealed,
    RenderContext renderContext,
  );
}
