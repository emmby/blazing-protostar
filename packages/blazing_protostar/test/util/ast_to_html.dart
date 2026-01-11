import 'dart:convert';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';

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
      // 1. Strip leading hashes (allow up to 3 spaces indent)
      // Note: We use replaceFirst to only remove the opening syntax
      var cleanContent = content.replaceFirst(
        RegExp(r'^[ ]{0,3}#{1,6}[ \t]*'),
        '',
      );

      // 2. Strip trailing hashes (must be preceded by space)
      // We look for " space + hashes + optional space + EOL"
      cleanContent = cleanContent.replaceFirst(RegExp(r'[ \t]+#+[ \t]*$'), '');

      // Special case: If content is NOW just hashes (e.g. "### ###" -> "###"),
      // it means the leading strip consumed the separator space.
      // Since it's a valid Header, these are closing hashes.
      if (RegExp(r'^#+[ \t]*$').hasMatch(cleanContent)) {
        cleanContent = '';
      }

      // 3. Trim remaining whitespace (CommonMark trims header content)
      cleanContent = cleanContent.trim();

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
    } else if (node is EscapeNode) {
      return content; // Render the escaped char without the backslash
    }

    return content;
  }

  @override
  String visitText(TextNode node) {
    return htmlEscape.convert(node.text);
  }
}
