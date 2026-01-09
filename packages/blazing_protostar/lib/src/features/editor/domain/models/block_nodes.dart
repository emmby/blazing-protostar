import 'node.dart';

abstract class BlockNode extends ElementNode {
  BlockNode({
    required super.children,
    required super.start,
    required super.end,
  });
}

class DocumentNode extends BlockNode {
  DocumentNode({
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'document';
}

class HeaderNode extends BlockNode {
  final int level;

  HeaderNode({
    required this.level,
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'header';
}

class ParagraphNode extends BlockNode {
  ParagraphNode({
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'paragraph';
}

class UnorderedListNode extends BlockNode {
  UnorderedListNode({
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'unordered_list';
}

class OrderedListNode extends BlockNode {
  OrderedListNode({
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'ordered_list';
}

class ListItemNode extends BlockNode {
  ListItemNode({
    required super.children,
    required super.start,
    required super.end,
  });

  @override
  String get type => 'list_item';
}
