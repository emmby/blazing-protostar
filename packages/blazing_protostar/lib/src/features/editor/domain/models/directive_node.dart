import 'node.dart';

class InlineDirectiveNode extends ElementNode {
  final String name;
  final String? args;
  final Map<String, String>? attributes;

  InlineDirectiveNode({
    required this.name,
    required List<Node> children,
    required int start,
    required int end,
    this.args,
    this.attributes,
  }) : super(children: children, start: start, end: end);

  @override
  String get type => 'directive';
}
