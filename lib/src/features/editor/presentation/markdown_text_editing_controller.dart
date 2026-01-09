import 'package:flutter/material.dart';
import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/block_nodes.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/inline_nodes.dart';

class MarkdownTextEditingController extends TextEditingController {
  final MarkdownParser _parser;
  final Duration _throttleDuration;

  MarkdownTextEditingController({
    String? text,
    MarkdownParser parser = const MarkdownParser(),
    Duration throttleDuration = const Duration(
      milliseconds: 16,
    ), // Frame budget
  }) : _parser = parser,
       _throttleDuration = throttleDuration,
       super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // 1. Parse the current text (Sync for now, might need isolates for massive docs)
    final document = _parser.parse(text);

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
