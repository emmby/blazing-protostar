import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:flutter/widgets.dart';

/// Provides context for rendering nodes.
///
/// Gives renderers access to controller state and the ability to recursively
/// render child nodes.
class RenderContext {
  /// The full text being rendered
  final String text;

  /// Whether WYSIWYG mode is enabled
  final bool isWysiwygMode;

  /// Function to recursively render child nodes
  final InlineSpan Function(Node node, TextStyle style, Node? parent)
  renderChild;

  /// Function to check if a node should be revealed (cursor proximity)
  final bool Function(Node node) shouldRevealNode;

  const RenderContext({
    required this.text,
    required this.isWysiwygMode,
    required this.renderChild,
    required this.shouldRevealNode,
  });
}
