import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownParser _parser;

  // Reactive State for the Toolbar
  final ValueNotifier<Set<String>> activeStyles = ValueNotifier({});

  DocumentNode? _lastParsedDocument;

  MarkdownTextEditingController({
    super.text,
    MarkdownParser parser = const MarkdownParser(),
    Duration throttleDuration = const Duration(milliseconds: 16),
  }) : _parser = parser,
       super() {
    addListener(_updateActiveStyles);
  }

  @override
  void dispose() {
    removeListener(_updateActiveStyles);
    activeStyles.dispose();
    super.dispose();
  }

  void _updateActiveStyles() {
    // 1. If we have no document, we can't check styles.
    if (_lastParsedDocument == null) return;

    // 2. Identify active styles at the current cursor position
    final newStyles = <String>{};
    final currentOffset = selection.baseOffset;

    if (currentOffset < 0) {
      if (activeStyles.value.isNotEmpty) activeStyles.value = {};
      return;
    }

    // Traverse the AST to find nodes spanning this offset.
    // Optimization: BlockParser sorts nodes by offset.
    // We can do a simple search.
    for (final node in _lastParsedDocument!.children) {
      if (node.start <= currentOffset && node.end >= currentOffset) {
        _collectStyles(node, currentOffset, newStyles);
        break; // Found the block, no need to check others (usually)
      }
    }

    // Update Notifier if changed
    // Sets equality check manually or rely on ValueNotifier?
    // ValueNotifier uses ==. Set equality defaults to Identity in Dart.
    // matchesCheck needed.
    if (!_areSetsEqual(activeStyles.value, newStyles)) {
      activeStyles.value = newStyles;
    }
  }

  bool _areSetsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _collectStyles(Node node, int offset, Set<String> collected) {
    if (node is ElementNode) {
      if (node is! DocumentNode && node is! ParagraphNode) {
        // Add this node's type (e.g. 'bold', 'header')
        // Note: HeaderNode type?
        if (node is HeaderNode) collected.add('header');
        if (node is BoldNode) collected.add('bold');
        if (node is ItalicNode) collected.add('italic');
        if (node is LinkNode) collected.add('link');
        if (node is UnorderedListNode ||
            node is OrderedListNode ||
            node is ListItemNode) {
          collected.add('list');
        }
      }

      // Recurse into children
      for (final child in node.children) {
        if (child.start <= offset && child.end >= offset) {
          _collectStyles(child, offset, collected);
        }
      }
    }
  }

  void applyFormat(String type) {
    if (selection.baseOffset < 0) return;

    // 1. Inline Styles (Bold, Italic)
    if (type == 'bold' || type == 'italic') {
      final syntax = type == 'bold' ? '**' : '_';
      final len = syntax.length;

      if (selection.isCollapsed) {
        // Insert empty syntax: "**|**"
        final newText = text.replaceRange(
          selection.baseOffset,
          selection.baseOffset,
          '$syntax$syntax',
        );
        final newOffset = selection.baseOffset + len;

        value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
          composing: TextRange.empty,
        );
      } else {
        // Wrap selection: "**selection**"
        final range = selection;
        final selectedText = text.substring(range.start, range.end);
        final newText = text.replaceRange(
          range.start,
          range.end,
          '$syntax$selectedText$syntax',
        );
        final newOffset = range.end + (len * 2);

        value = value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newOffset),
          composing: TextRange.empty,
        );
      }
    }
    // 2. Line Styles (Header, List)
    else if (type == 'header' || type == 'list') {
      final prefix = type == 'header' ? '# ' : '- ';
      // Find start of line
      final start = text.lastIndexOf(
        '\n',
        selection.baseOffset - 1,
      ); // -1 to handle being AT the newline
      final lineStart = start == -1 ? 0 : start + 1;

      // Insert prefix at line start
      final newText = text.replaceRange(lineStart, lineStart, prefix);

      // Adjust cursor
      final newOffset = selection.baseOffset + prefix.length;

      value = value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
        composing: TextRange.empty,
      );
    }
    // 3. Link
    else if (type == 'link') {
      // [text](url)
      // Simple version: Insert `[]()` and put cursor in `[]`? Or wrap?
      // Wrap: `[selection](url)`

      if (selection.isCollapsed) {
        const insert = '[text](url)';
        final newText = text.replaceRange(
          selection.baseOffset,
          selection.baseOffset,
          insert,
        );
        // Select "text" so user can overwrite? Start: +1. End: +5.
        // Or just move to end?
        // Let's select "text".
        final newSelection = TextSelection(
          baseOffset: selection.baseOffset + 1,
          extentOffset: selection.baseOffset + 5,
        );

        value = value.copyWith(
          text: newText,
          selection: newSelection,
          composing: TextRange.empty,
        );
      } else {
        final range = selection;
        final selectedText = text.substring(range.start, range.end);
        final insert = '[$selectedText](url)';
        final newText = text.replaceRange(range.start, range.end, insert);

        // Select "url" so user can overwrite?
        // Offset = range.start + 1 + selectedText.length + 2 ("text](").
        final urlStart = range.start + 1 + selectedText.length + 2;
        final urlEnd = urlStart + 3; // "url"

        value = value.copyWith(
          text: newText,
          selection: TextSelection(baseOffset: urlStart, extentOffset: urlEnd),
          composing: TextRange.empty,
        );
      }
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 1. Parse the current text
    final document = _parser.parse(text);
    _lastParsedDocument = document; // Cache for selection tracking

    // 2. Convert AST to TextSpans with Styling
    // We pass the "default" style (likely from TextField) as the base.
    return _renderNode(document, style ?? const TextStyle());
  }

  TextSpan _renderNode(Node node, TextStyle currentStyle) {
    if (node is TextNode) {
      return TextSpan(text: node.text, style: currentStyle);
    }

    if (node is ElementNode) {
      final childrenSpans = <InlineSpan>[];

      // Calculate new style based on Node Type
      var newStyle = currentStyle;

      if (node is HeaderNode) {
        // Headers scale based on level
        final size = 24.0 - (node.level * 2.0); // Simple scaling
        newStyle = newStyle.copyWith(
          fontSize: size,
          fontWeight: FontWeight.bold,
          color: Colors.black87, // Phase 1 theme hardcoded
        );
      } else if (node is BoldNode) {
        newStyle = newStyle.copyWith(fontWeight: FontWeight.bold);
      } else if (node is ItalicNode) {
        newStyle = newStyle.copyWith(fontStyle: FontStyle.italic);
      } else if (node is LinkNode) {
        newStyle = newStyle.copyWith(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        );
      } else if (node is EscapeNode) {
        // Dim the backslash? Or just render plain?
        newStyle = newStyle.copyWith(color: Colors.grey);
      }

      // Dim Syntax Characters?
      // My AST currently has the syntax explicitly in the TextNode children for Bold/Italic
      // e.g. BoldNode -> [TextNode("**"), TextNode("bold"), TextNode("**")]
      // Wait, my parser implementation kept the syntax markers OUT of the parsed content
      // but managed the 'start/end' indices.
      //
      // Let's re-read InlineParser.
      //
      // _parseBold:
      // nodes.add(BoldNode(children: [TextNode("innerText")]...))
      // It DROPPED the "**" from the tree!
      //
      // CRITICAL REALIZATION:
      // My README said "Keep control characters visible".
      // But my `_parseBold` implementation logic:
      // `start: textNode.start + matchStart + 2`
      // It skipped the syntax chars! They are NOT in the tree children.
      //
      // But `buildTextSpan` must return the spans for the *entire* text
      // or the TextField cursor will desync.
      // If I return TextSpans that omit characters that exists in `text`,
      // Flutter will crash or behave wildly.
      //
      // FIX:
      // My Editor Renderer MUST insert the missing syntax characters back as spans,
      // OR my Parser MUST include them in the AST.
      //
      // Given "Phase 1: Visible Syntax", the Parser SHOULD include them.
      //
      // For now, to allow the code to run without crashing,
      // I will perform a "Gap Filling" strategy in this render method.
      // I know `node.start` and `node.children[i].start`.
      // If there is a gap, that's syntax. I will render it dimmed.

      int currentPos = node.start;

      for (final child in node.children) {
        // Fill gap before child (Syntax characters or Whitespace)
        if (child.start > currentPos) {
          final gapText = text.substring(currentPos, child.start);
          childrenSpans.add(
            TextSpan(
              text: gapText,
              // Apply dimmed style for syntax, but maybe Keep normal style for generic whitespace?
              // Simple heuristic: If it looks like syntax (*, _, #, [, ]), dim it.
              style: currentStyle.copyWith(color: Colors.grey),
            ),
          );
        }

        childrenSpans.add(_renderNode(child, newStyle));
        currentPos = child.end;
      }

      // Fill gap after last child (Syntax characters)
      if (currentPos < node.end) {
        final gapText = text.substring(currentPos, node.end);
        childrenSpans.add(
          TextSpan(
            text: gapText,
            style: currentStyle.copyWith(color: Colors.grey),
          ),
        );
      }

      // Hack for DocumentNode: It might have gaps between blocks (Newlines) that are NOT part of any block.
      // But `node.end` for Document covers the whole string.
      // So the logic above "Gap after last child" actually handles the trailing newline
      // ONLY IF the document end is correct.
      //
      // Wait, `_renderNode` is called regarding `node`.
      // If `DocumentNode` has children `[Para1(0-5), Para2(6-10)]`.
      // Loop ends at 5.
      // Next child starts at 6.
      // Loop gap detects 5->6 (The newline).
      // It renders it.
      //
      // So... my logic actually works for inter-block newlines too!
      // Provided `DocumentNode.start` is 0 and `end` is length.

      return TextSpan(children: childrenSpans);
    }

    return const TextSpan(text: "");
  }
}
