import '../models/node.dart';
import 'inline_lexer.dart';

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
    // 1. Scan text into tokens
    final lexer = InlineLexer(textNode.text, baseOffset: textNode.start);
    final tokens = lexer.scan();

    // 2. Parse tokens into nodes using a Delimiter Stack approach
    return _parseTokens(tokens);
  }

  /// Parses a list of tokens into a list of AST Nodes.
  // --- Stack-Based Parsing Strategy ---

  List<Node> _parseTokens(List<Token> tokens) {
    // 1. Convert all tokens to basic Nodes first (Text or Delimiter Placeholder).
    final List<Node> nodes = [];

    for (int i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      // Update previous delimiter's canOpen if this is not a delimiter
      if (nodes.isNotEmpty && nodes.last is _DelimiterNode) {
        final prevDelim = nodes.last as _DelimiterNode;
        bool startsWithSpace = false;
        if (t.type == TokenType.text && t.content.isNotEmpty) {
          startsWithSpace =
              t.content.startsWith(' ') ||
              t.content.startsWith('\t') ||
              t.content.startsWith('\n');
        } else if (t.type == TokenType.text && t.content.isEmpty) {
          // Empty text? rarely happens
        } else if (t.type == TokenType.escape) {
          // Escape is not whitespace
        } else if (t.type == TokenType.openBracket) {
          // [ is not whitespace
        }
        // If current token is delimiter, it merges below, so prevDelim stays valid.
        // But if current token prevents opening (e.g. whitespace), we mark it.
        // Actually merging handles 'canOpen' deferral. We care if run ENDS here.
        // If t is delimiter, loop continues.
        // If t is NOT same delimiter, run ends.
        // But logic below handles merging.
        // Simplest: Always update tentative canOpen based on current token.
        // If merging happens, the "last" node changes, but canOpen is re-evaluated for the run end eventually.
        prevDelim.canOpen = !startsWithSpace;
      }
      if (t.type == TokenType.star || t.type == TokenType.underscore) {
        // Delimiter
        bool precededBySpace = true;
        if (i > 0) {
          final prevT = tokens[i - 1];
          if (prevT.type == TokenType.text && prevT.content.isNotEmpty) {
            final lastChar = prevT.content[prevT.content.length - 1];
            precededBySpace =
                (lastChar == ' ' || lastChar == '\t' || lastChar == '\n');
          } else if (prevT.type == TokenType.text && prevT.content.isEmpty) {
            // Skip
          } else {
            // Punctuation/Other Delimiter is NOT whitespace.
            precededBySpace = false;
          }
        } else {
          // Start of line is treated as whitespace for "preceded by" check?
          // "A delimiter run is left-flanking if... not followed by Unicode whitespace... and either not followed by punctuation or..."
          // "A delimiter run is right-flanking if... not preceded by Unicode whitespace..."
          // If start of line (Void), is it whitespace?
          // CommonMark: "A left-flanking delimiter run" (can open).
          // "A right-flanking delimiter run" (can close).
          // If Left-Flanking, it can Open.
          // If Right-Flanking, it can Close.

          // At start of line `**foo`. Preceded by Void. Not Preceded by Whitespace?
          // Void acts like space?
          // "For purposes of this definition... the beginning and the end of the line count as Unicode whitespace".
          // YES. Void is Space.
          precededBySpace = true;
        }

        final node = _DelimiterNode(
          tokenType: t.type,
          count: 1,
          start: t.start,
          end: t.end,
          char: t.content,
          canClose:
              !precededBySpace, // If preceded by space, CANNOT Close. Correct.
          canOpen: true, // Optimistic/Default. Updated by next iteration.
        );

        // Merge adjacent DelimiterNodes of same type
        if (nodes.isNotEmpty && nodes.last is _DelimiterNode) {
          final prev = nodes.last as _DelimiterNode;
          if (prev.tokenType == node.tokenType) {
            // Immutable replacement for merge
            nodes[nodes.length - 1] = _DelimiterNode(
              tokenType: prev.tokenType,
              count: prev.count + 1,
              start: prev.start,
              end: node.end,
              char: prev.char,
            );
            continue;
          }
        }
        nodes.add(node);
      } else if (t.type == TokenType.openBracket) {
        final linkInfo = _findLinkMatch(tokens, i);
        if (linkInfo != null) {
          final innerTokens = tokens.sublist(i + 1, linkInfo.closeBracketIndex);
          final innerChildren = _parseTokens(innerTokens);

          nodes.add(
            LinkNode(
              href: linkInfo.url,
              children: innerChildren,
              start: t.start,
              end: linkInfo.endOffset,
            ),
          );

          i = linkInfo.nextIndex - 1;
          continue;
        }

        nodes.add(TextNode(text: t.content, start: t.start, end: t.end));
      } else if (t.type == TokenType.escape) {
        nodes.add(
          TextNode(text: t.content.substring(1), start: t.start, end: t.end),
        );
      } else {
        if (nodes.isNotEmpty &&
            nodes.last is TextNode &&
            nodes.last is! _DelimiterNode) {
          final prev = nodes.last as TextNode;
          nodes[nodes.length - 1] = TextNode(
            text: prev.text + t.content,
            start: prev.start,
            end: t.end,
          );
        } else {
          nodes.add(TextNode(text: t.content, start: t.start, end: t.end));
        }
      }
    }

    // Post-loop check: Last node followed by EOF (whitespace)
    if (nodes.isNotEmpty && nodes.last is _DelimiterNode) {
      (nodes.last as _DelimiterNode).canOpen = false;
    }

    // 1.5 Refine Delimiters (Flanking Rules)
    _refineDelimiters(nodes);

    // 2. Process Emphasis using Stack
    _processEmphasis(nodes);

    // 3. Final cleaning: Convert remaining DelimiterNodes to TextNodes
    final finalNodes = <Node>[];
    for (final node in nodes) {
      if (node is _DelimiterNode) {
        finalNodes.add(
          TextNode(
            text: node.char * node.count,
            start: node.start,
            end: node.end,
          ),
        );
      } else {
        finalNodes.add(node);
      }
    }

    return _mergeTextNodes(finalNodes);
  }

  void _refineDelimiters(List<Node> nodes) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is _DelimiterNode) {
        // 1. Check Preceding context
        bool precededBySpace = true;
        bool precededByPunctuation = false;

        if (i > 0) {
          final prev = nodes[i - 1];
          if (prev is TextNode) {
            final text = prev.text;
            if (text.isNotEmpty) {
              final lastChar = text[text.length - 1];
              precededBySpace =
                  (lastChar == ' ' || lastChar == '\t' || lastChar == '\n');
              precededByPunctuation = RegExp(
                r'''[!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~]''',
              ).hasMatch(lastChar);
            } else {
              // Empty text node? Treat as non-existent.
            }
          } else {
            // Other Node (Link, etc) -> Treated as Punctuation?
            // CommonMark strict: "Unicode punctuation" vs "Unicode whitespace".
            // Anything else is a character.
            // Links/Images are "Content". So treated as Non-Space, Non-Punctuation (like a Letter).
            precededBySpace = false;
            precededByPunctuation = false;
          }
        } else {
          // Start of line -> Whitespace (Void)
          precededBySpace = true;
          precededByPunctuation = false;
        }

        // 2. Check Following context
        bool followedBySpace = true;
        bool followedByPunctuation = false;

        if (i < nodes.length - 1) {
          final next = nodes[i + 1];
          if (next is TextNode) {
            final text = next.text;
            if (text.isNotEmpty) {
              final firstChar = text[0];
              followedBySpace =
                  (firstChar == ' ' || firstChar == '\t' || firstChar == '\n');
              followedByPunctuation = RegExp(
                r'''[!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~]''',
              ).hasMatch(firstChar);
            }
          } else {
            followedBySpace = false;
            followedByPunctuation = false;
          }
        } else {
          // End of line -> Whitespace (Void)
          followedBySpace = true;
          followedByPunctuation = false;
        }

        // 3. Determine Flanking
        // Left-flanking: not followed by Unicode whitespace, and either not followed by Unicode punctuation or (preceded by Unicode whitespace or Unicode punctuation).
        final isLeftFlanking =
            !followedBySpace &&
            (!followedByPunctuation ||
                (precededBySpace || precededByPunctuation));

        // Right-flanking: not preceded by Unicode whitespace, and either not preceded by Unicode punctuation or (followed by Unicode whitespace or Unicode punctuation).
        final isRightFlanking =
            !precededBySpace &&
            (!precededByPunctuation ||
                (followedBySpace || followedByPunctuation));

        // 4. Set canOpen / canClose
        if (node.char == '_') {
          // Underscore Rules
          node.canOpen =
              isLeftFlanking && (!isRightFlanking || precededByPunctuation);
          node.canClose =
              isRightFlanking && (!isLeftFlanking || followedByPunctuation);
        } else {
          // Asterisk Rules (Permissive)
          node.canOpen = isLeftFlanking;
          node.canClose = isRightFlanking;
        }
      }
    }
  }

  void _processEmphasis(List<Node> nodes) {
    final List<int> openers = [];

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node is _DelimiterNode) {
        bool matched = false;

        for (int s = openers.length - 1; s >= 0; s--) {
          final openerIndex = openers[s];
          if (openerIndex >= nodes.length) continue;
          final openerNode = nodes[openerIndex];

          if (openerNode is! _DelimiterNode) continue;

          if (openerNode.tokenType == node.tokenType) {
            // Check flanking rules
            if (!node.canClose) continue;
            if (!openerNode.canOpen) continue;

            // Match!
            bool isBold = (node.count >= 2 && openerNode.count >= 2);
            int consumed = isBold ? 2 : 1;

            // Reduce counts
            node.count -= consumed;
            openerNode.count -= consumed;

            final childrenIndices = i - openerIndex - 1;
            final children = (childrenIndices > 0)
                ? nodes.sublist(openerIndex + 1, i)
                : <Node>[];

            final cleanedChildren = _cleanNodes(children);

            final newNode = isBold
                ? BoldNode(
                    children: cleanedChildren,
                    start: openerNode.start,
                    end: node.end,
                  )
                : ItalicNode(
                    children: cleanedChildren,
                    start: openerNode.start,
                    end: node.end,
                  );

            nodes[openerIndex + 1] = newNode;
            if (i > openerIndex + 1) {
              nodes.removeRange(openerIndex + 2, i + 1);
            }

            if (openerNode.count == 0) {
              nodes.removeAt(openerIndex);
              openers.removeAt(s);
              i = openerIndex - 1;
            } else {
              i = openerIndex;
            }

            if (node.count > 0) {
              int insertPos = (openerNode.count <= 0)
                  ? openerIndex + 1
                  : openerIndex + 2;
              if (insertPos > nodes.length) insertPos = nodes.length;
              nodes.insert(insertPos, node);
            }

            openers.removeWhere((idx) => idx > openerIndex);
            matched = true;
            break;
          }
        }

        if (!matched) {
          openers.add(i);
        }
      }
    }
  }

  List<Node> _cleanNodes(List<Node> nodes) {
    final out = <Node>[];
    for (final n in nodes) {
      if (n is _DelimiterNode) {
        out.add(TextNode(text: n.char * n.count, start: n.start, end: n.end));
      } else {
        out.add(n);
      }
    }
    return out;
  }

  List<Node> _mergeTextNodes(List<Node> nodes) {
    if (nodes.isEmpty) return nodes;
    final merged = <Node>[];
    TextNode? currentText;

    for (final node in nodes) {
      if (node is TextNode) {
        if (currentText == null) {
          currentText = node;
        } else {
          currentText = TextNode(
            text: currentText.text + node.text,
            start: currentText.start,
            end: node.end,
          );
        }
      } else {
        if (currentText != null) {
          merged.add(currentText);
          currentText = null;
        }
        merged.add(node);
      }
    }
    if (currentText != null) merged.add(currentText);
    return merged;
  }

  _EncodeMatch? _findLinkMatch(List<Token> tokens, int openBracketIndex) {
    int depth = 1;
    int closeIndex = -1;

    for (int i = openBracketIndex + 1; i < tokens.length; i++) {
      if (tokens[i].type == TokenType.openBracket) {
        depth++;
      } else if (tokens[i].type == TokenType.closeBracket) {
        depth--;
        if (depth == 0) {
          closeIndex = i;
          break;
        }
      }
    }

    if (closeIndex == -1) return null;

    if (closeIndex + 1 >= tokens.length) return null;
    if (tokens[closeIndex + 1].type != TokenType.openParen) return null;

    int openParenIndex = closeIndex + 1;
    int urlEndIndex = -1;
    String url = '';
    int pDepth = 1;

    for (int i = openParenIndex + 1; i < tokens.length; i++) {
      final t = tokens[i];
      if (t.type == TokenType.openParen) {
        pDepth++;
      } else if (t.type == TokenType.closeParen) {
        pDepth--;
        if (pDepth == 0) {
          urlEndIndex = i;
          break;
        }
      }
      if (pDepth > 0) url += t.content;
    }

    if (urlEndIndex == -1) return null;

    final endOffset = tokens[urlEndIndex].end;

    return _EncodeMatch(
      closeBracketIndex: closeIndex,
      url: url,
      endOffset: endOffset,
      nextIndex: urlEndIndex + 1,
    );
  }
}

class _EncodeMatch {
  final int closeBracketIndex;
  final String url;
  final int endOffset;
  final int nextIndex;

  _EncodeMatch({
    required this.closeBracketIndex,
    required this.url,
    required this.endOffset,
    required this.nextIndex,
  });
}

class _DelimiterNode extends TextNode {
  final TokenType tokenType;
  int count; // Mutable count for reduction
  final String char;
  bool canOpen;
  bool canClose;

  _DelimiterNode({
    required this.tokenType,
    required this.count,
    required super.start,
    required super.end,
    required this.char,
    this.canOpen = true,
    this.canClose = true,
  }) : super(text: char * count);

  @override
  String get type => 'text'; // Pretend to be text for visitors

  @override
  String toString() =>
      '_DelimiterNode("$char" x $count, $tokenType, O=$canOpen, C=$canClose)';

  void increment() {
    count++;
    // end is final in Node, so we can't update it here.
    // We must rely on immutable replacement during merging.
  }
}
