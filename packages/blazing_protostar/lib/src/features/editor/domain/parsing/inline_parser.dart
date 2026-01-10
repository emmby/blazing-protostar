import '../models/node.dart';

class InlineParser {
  final DocumentNode document;

  InlineParser(this.document);

  void parse() {
    _visit(document);
  }

  void _visit(ElementNode node) {
    // If it's a leaf block (Header or Paragraph or ListItem), process its text children
    if (node is HeaderNode || node is ParagraphNode || node is ListItemNode) {
      _processBlock(node);
      return;
    }

    // Recurse strictly for structural blocks (List, Document)
    // Note: This naive recurse assumes only certain nodes capture text.
    // In a full implementation, we'd be more generic.
    for (final child in node.children) {
      if (child is ElementNode) _visit(child);
    }
  }

  void _processBlock(ElementNode block) {
    final originalChildren = List<Node>.from(block.children);
    final newChildren = <Node>[];

    for (final child in originalChildren) {
      if (child is TextNode) {
        newChildren.addAll(_parseText(child));
      } else {
        newChildren.add(child);
      }
    }

    // Update the block's children
    block.children = newChildren;
  }

  List<Node> _parseText(TextNode textNode) {
    // Pipeline: Escapes -> Bold -> Italic

    // 1. Parse Escapes (Priority 1: Protects chars from other parsers)
    final afterEscapes = _parseEscapes(textNode);

    // 2. Parse Bolds
    final afterBold = <Node>[];
    for (final node in afterEscapes) {
      if (node is TextNode) {
        afterBold.addAll(_parseBold(node));
      } else {
        afterBold.add(node);
      }
    }

    // 3. Parse Links
    final afterLinks = <Node>[];
    for (final node in afterBold) {
      if (node is TextNode) {
        afterLinks.addAll(_parseLinks(node));
      } else {
        afterLinks.add(node);
      }
    }

    // 4. Parse Italics
    final afterItalic = <Node>[];
    for (final node in afterLinks) {
      if (node is TextNode) {
        afterItalic.addAll(_parseItalic(node));
      } else {
        afterItalic.add(node);
      }
    }

    return afterItalic;
  }

  List<Node> _parseLinks(TextNode textNode) {
    final text = textNode.text;
    final nodes = <Node>[];
    int currentIndex = 0;

    // Naive Link Regex: [text](url)
    final regex = RegExp(r'\[([^\]]+)\]\(([^\)]+)\)');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.start > currentIndex) {
        nodes.add(
          TextNode(
            text: text.substring(currentIndex, match.start),
            start: textNode.start + currentIndex,
            end: textNode.start + match.start,
          ),
        );
      }

      final linkText = match.group(1)!;
      final linkUrl = match.group(2)!;
      final matchStart = match.start;
      final matchEnd = match.end;

      nodes.add(
        LinkNode(
          href: linkUrl,
          children: [
            TextNode(
              text: linkText,
              start: textNode.start + matchStart + 1,
              end: textNode.start + matchStart + 1 + linkText.length,
            ),
          ],
          start: textNode.start + matchStart,
          end: textNode.start + matchEnd,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      nodes.add(
        TextNode(
          text: text.substring(currentIndex),
          start: textNode.start + currentIndex,
          end: textNode.start + text.length,
        ),
      );
    }

    return nodes.isNotEmpty ? nodes : [textNode];
  }

  List<Node> _parseEscapes(TextNode textNode) {
    final text = textNode.text;
    final nodes = <Node>[];
    int currentIndex = 0;

    // CommonMark escapes: \ + ASCII punctuation
    final regex = RegExp(r'\\([!-/:-@\[-`{-~])');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.start > currentIndex) {
        nodes.add(
          TextNode(
            text: text.substring(currentIndex, match.start),
            start: textNode.start + currentIndex,
            end: textNode.start + match.start,
          ),
        );
      }

      final escapedChar = match.group(1)!;
      final matchStart = match.start;
      final matchEnd = match.end;

      nodes.add(
        EscapeNode(
          children: [
            TextNode(
              text: escapedChar,
              start: textNode.start + matchStart + 1, // Skip \
              end: textNode.start + matchEnd,
            ),
          ],
          start: textNode.start + matchStart,
          end: textNode.start + matchEnd,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      nodes.add(
        TextNode(
          text: text.substring(currentIndex),
          start: textNode.start + currentIndex,
          end: textNode.start + text.length,
        ),
      );
    }

    return nodes.isNotEmpty ? nodes : [textNode];
  }

  List<Node> _parseBold(TextNode textNode) {
    final text = textNode.text;
    final nodes = <Node>[];
    int currentIndex = 0;

    // **bold**
    final regex = RegExp(r'\*\*([^\*]+)\*\*');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.start > currentIndex) {
        nodes.add(
          TextNode(
            text: text.substring(currentIndex, match.start),
            start: textNode.start + currentIndex,
            end: textNode.start + match.start,
          ),
        );
      }

      final innerText = match.group(1)!;
      final matchStart = match.start;
      final matchEnd = match.end;

      nodes.add(
        BoldNode(
          children: [
            TextNode(
              text: innerText,
              start: textNode.start + matchStart + 2,
              end: textNode.start + matchEnd - 2,
            ),
          ],
          start: textNode.start + matchStart,
          end: textNode.start + matchEnd,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      nodes.add(
        TextNode(
          text: text.substring(currentIndex),
          start: textNode.start + currentIndex,
          end: textNode.start + text.length,
        ),
      );
    }

    return nodes.isNotEmpty ? nodes : [textNode];
  }

  List<Node> _parseItalic(TextNode textNode) {
    final text = textNode.text;
    final nodes = <Node>[];
    int currentIndex = 0;

    // *italic*
    // Note: This regex is very naive. It fails on *foo **bar** baz*
    // But for MVP Phase 1 (Simple formatting), it allows us to progress.
    final regex = RegExp(r'\*([^\*]+)\*');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      if (match.start > currentIndex) {
        nodes.add(
          TextNode(
            text: text.substring(currentIndex, match.start),
            start: textNode.start + currentIndex,
            end: textNode.start + match.start,
          ),
        );
      }

      final innerText = match.group(1)!;
      final matchStart = match.start;
      final matchEnd = match.end;

      nodes.add(
        ItalicNode(
          children: [
            TextNode(
              text: innerText,
              start: textNode.start + matchStart + 1, // Skip *
              end: textNode.start + matchEnd - 1, // Skip *
            ),
          ],
          start: textNode.start + matchStart,
          end: textNode.start + matchEnd,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      nodes.add(
        TextNode(
          text: text.substring(currentIndex),
          start: textNode.start + currentIndex,
          end: textNode.start + text.length,
        ),
      );
    }

    return nodes.isNotEmpty ? nodes : [textNode];
  }
}
