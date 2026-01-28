import 'node.dart';

class InlineDirectiveNode extends ElementNode {
  final String name;
  final String? args;
  final Map<String, String>? attributes;

  InlineDirectiveNode({
    required this.name,
    required super.children,
    required super.start,
    required super.end,
    this.args,
    this.attributes,
  });

  @override
  String get type => 'directive';
}
