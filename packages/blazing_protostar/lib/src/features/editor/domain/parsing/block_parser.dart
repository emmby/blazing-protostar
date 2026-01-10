import '../models/node.dart';

class BlockParser {
  final String text;
  final List<String> _lines;
  final List<int> _lineOffsets;

  BlockParser(this.text) : _lines = [], _lineOffsets = [] {
    _splitLines();
  }

  void _splitLines() {
    int start = 0;
    // Basic line splitting that tracks offsets
    // This handles \n. (CRLF might need more work but MVP is fine)
    final rawLines = text.split('\n');
    for (final line in rawLines) {
      _lines.add(line);
      _lineOffsets.add(start);
      // +1 for the newline char that split removed (except maybe last one)
      start += line.length + 1;
    }
  }

  DocumentNode parse() {
    final children = <BlockNode>[];
    int lineIndex = 0;

    while (lineIndex < _lines.length) {
      final line = _lines[lineIndex];
      final offset = _lineOffsets[lineIndex];

      // 1. Check for ATX Header
      final headerMatch = RegExp(r'^(#{1,6})(?:[ \t]+|$)').firstMatch(line);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        children.add(
          HeaderNode(
            level: level,
            children: [
              TextNode(text: line, start: offset, end: offset + line.length),
            ],
            start: offset,
            end: offset + line.length,
          ),
        );
        lineIndex++;
        continue;
      }

      // 2. Check for List Item (Unordered detected by '- ' or '* ' or '+ ')
      final ulMatch = RegExp(r'^([*+-])([ \t]+|$)').firstMatch(line);
      if (ulMatch != null) {
        // TODO: Handle list grouping. For now, just emit a ListItemNode wrapped in a generic List?
        // Or strictly follow spec where Lists contains ListItems.
        // For line-by-line MVP, we might treat each item as a list item block.
        // But the AST requires List -> ListItem.
        // Let's defer strict list grouping to "Phase 1.5".
        // For verification, identifying it is enough.
        children.add(
          UnorderedListNode(
            children: [
              ListItemNode(
                children: [
                  TextNode(
                    text: line,
                    start: offset,
                    end: offset + line.length,
                  ),
                ],
                start: offset,
                end: offset + line.length,
              ),
            ],
            start: offset,
            end: offset + line.length,
          ),
        );
        lineIndex++;
        continue;
      }

      // 3. Fallback: Paragraph
      // Check for empty lines first?
      if (line.trim().isEmpty) {
        // Just skip empty lines (or add specific spacing nodes?)
        // CommonMark ignores blank lines between blocks usually.
        lineIndex++;
        continue;
      }

      children.add(
        ParagraphNode(
          children: [
            TextNode(text: line, start: offset, end: offset + line.length),
          ],
          start: offset,
          end: offset + line.length,
        ),
      );
      lineIndex++;
    }

    // Post-processing: Merge adjacent ParagraphNodes?
    // No, better to do it during the loop loop or just merge adjacent paragraphs here.
    // Actually, the loop above emits a Paragraph for EVERY line.
    // Let's refactor the loop to merge "Paragraph" lines into the *previous* Paragraph if valid.

    final mergedChildren = <BlockNode>[];
    for (final child in children) {
      if (child is ParagraphNode &&
          mergedChildren.isNotEmpty &&
          mergedChildren.last is ParagraphNode &&
          child.start == mergedChildren.last.end + 1) {
        final lastParagraph = mergedChildren.last as ParagraphNode;
        final lastTextNode = lastParagraph.children.first as TextNode;
        final currentTextNode = child.children.first as TextNode;

        // Merge logic
        // We need to insert the missing newline between them
        // Note: offsets might become non-contiguous if we aren't careful,
        // but our basic _splitLines ensures offsets are sequential (line N end + 1 = line N+1 start).

        final newText = lastTextNode.text + '\n' + currentTextNode.text;

        // Replace the last paragraph with a merged one
        mergedChildren.removeLast();
        mergedChildren.add(
          ParagraphNode(
            children: [
              TextNode(
                text: newText,
                start: lastTextNode.start,
                end: currentTextNode.end,
              ),
            ],
            start: lastParagraph.start,
            end: child.end,
          ),
        );
      } else {
        mergedChildren.add(child);
      }
    }

    // Determine document end correctly
    final docEnd = text.isEmpty ? 0 : text.length;
    return DocumentNode(children: mergedChildren, start: 0, end: docEnd);
  }
}
