import '../models/node.dart';
import '../models/block_nodes.dart';
import 'block_parser.dart';
import 'inline_parser.dart';

/// The main entry point for parsing Markdown text into an AST.
///
/// Follows the standard two-phase strategy:
/// 1. Block Parsing: transform lines into a tree of BlockNodes.
/// 2. Inline Parsing: transform text within leaf blocks into InlineNodes.
class MarkdownParser {
  const MarkdownParser();

  DocumentNode parse(String text) {
    // 1. Block Phase
    // Use a simpler line splitter that tracks offsets if needed,
    // but for now standard split is fine for the MVP logic.
    // We might need to map lines back to global offsets later.
    final parser = BlockParser(text);
    final document = parser.parse();

    // 2. Inline Phase
    final inlineParser = InlineParser(document);
    inlineParser.parse();

    return document;
  }
}
