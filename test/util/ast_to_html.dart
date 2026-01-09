import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/block_nodes.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/inline_nodes.dart';

class AstToHtmlRenderer implements NodeVisitor<String> {
  const AstToHtmlRenderer();

  String render(Node node) {
    return node.accept(this);
  }

  @override
  String visitElement(ElementNode node) {
    final buffer = StringBuffer();
    for (final child in node.children) {
      buffer.write(child.accept(this));
    }
    final content = buffer.toString();

    if (node is DocumentNode) {
      return content;
    } else if (node is HeaderNode) {
      // Strip leading hashes/whitespace from the content string for spec compliance.
      // e.g. "# Hex" -> "Hex"
      // Note: We access the raw content from children, which currently includes the syntax.
      final cleanContent = content.replaceAll(RegExp(r'^#{1,6}[ \t]*'), '');
      return '<h${node.level}>$cleanContent</h${node.level}>\n';
    } else if (node is ParagraphNode) {
      return '<p>$content</p>\n';
    } else if (node is UnorderedListNode) {
      return '<ul>\n$content</ul>\n';
    } else if (node is OrderedListNode) {
      return '<ol>\n$content</ol>\n'; // MVP: Assumes start=1
    } else if (node is ListItemNode) {
      return '<li>$content</li>\n';
    } else if (node is BoldNode) {
      return '<strong>$content</strong>';
    } else if (node is ItalicNode) {
      return '<em>$content</em>';
    } else if (node is LinkNode) {
      return '<a href="${node.href}">$content</a>';
    }

    return content;
  }

  @override
  String visitText(TextNode node) {
    // Basic HTML escaping might be needed for spec compliance
    // (e.g. < -> &lt;)
    // For now, raw.
    return node.text;
  }
}
