import 'node.dart';

abstract class InlineNode extends ElementNode {
  InlineNode({
    required super.children,
    required super.start,
    required super.end,
  });
}

class BoldNode extends InlineNode {
  BoldNode({required super.children, required super.start, required super.end});

  @override
  String get type => 'bold';
}

class ItalicNode extends InlineNode {
  ItalicNode({
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'italic';
}

class LinkNode extends InlineNode {
  final String href;

  LinkNode({
    required this.href,
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'link';
}
