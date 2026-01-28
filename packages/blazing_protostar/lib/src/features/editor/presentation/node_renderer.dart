import 'package:flutter/widgets.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';

/// A function that builds a completely custom WidgetSpan for a given Markdown Node.
///
/// [context] is the build context.
/// [node] is the AST node being rendered (e.g. HeaderNode, BoldNode).
/// [style] is the base text style that would have been applied.
/// [isRevealed] is true if the cursor is near/inside this node (Edit Mode).
typedef NodeRenderer =
    InlineSpan Function(
      BuildContext context,
      Node node,
      TextStyle style,
      bool isRevealed, [
      Node? parent,
    ]);
