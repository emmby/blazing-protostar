export 'block_nodes.dart';
export 'inline_nodes.dart';
export 'directive_node.dart';

/// Base class for all AST nodes in the Markdown document.
///
/// Each node MUST track its exact [start] and [end] character offsets
/// in the source document to allow for precise styling updates.
abstract class Node {
  final int start;
  final int end;

  const Node(this.start, this.end);

  /// Returns the type of this node (e.g., 'paragraph', 'header', 'text').
  String get type;

  /// Accepts a visitor for traversing the AST.
  R accept<R>(NodeVisitor<R> visitor);

  @override
  String toString() => '$type($start, $end)';
}

/// A visitor interface for traversing the AST.
abstract class NodeVisitor<R> {
  R visitText(TextNode node);
  R visitElement(ElementNode node);
}

// Forward declarations
class TextNode extends Node {
  final String text;

  const TextNode({required this.text, required int start, required int end})
    : super(start, end);

  @override
  String get type => 'text';

  @override
  R accept<R>(NodeVisitor<R> visitor) => visitor.visitText(this);

  @override
  String toString() => 'TextNode("$text", $start-$end)';
}

abstract class ElementNode extends Node {
  List<Node> children;

  ElementNode({required this.children, required int start, required int end})
    : super(start, end);

  @override
  R accept<R>(NodeVisitor<R> visitor) => visitor.visitElement(this);
}
