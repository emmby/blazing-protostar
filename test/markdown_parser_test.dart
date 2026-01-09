import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/block_nodes.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/inline_nodes.dart';
import 'package:blazing_protostar/src/features/editor/domain/models/node.dart';

void main() {
  group('MarkdownParser', () {
    const parser = MarkdownParser();

    test('Parses Header', () {
      final doc = parser.parse('# Hello World');

      expect(doc.children.length, 1);
      final header = doc.children.first as HeaderNode;
      expect(header.level, 1);
      expect(header.children.length, 1);
      expect((header.children.first as TextNode).text, '# Hello World');
    });

    test('Parses Paragraph', () {
      final doc = parser.parse('Just a paragraph');

      expect(doc.children.length, 1);
      final p = doc.children.first as ParagraphNode;
      expect(p.children.length, 1);
      expect((p.children.first as TextNode).text, 'Just a paragraph');
    });

    test('Parses Bold inside Block', () {
      final doc = parser.parse('This is **bold** text');

      expect(doc.children.length, 1);
      final p = doc.children.first as ParagraphNode;

      // Expected structure: TextNode("This is "), BoldNode("bold"), TextNode(" text")
      // Based on my naive regex logic
      expect(p.children.length, 3);

      expect((p.children[0] as TextNode).text, 'This is ');
      expect(p.children[1], isA<BoldNode>());
      expect((p.children[1] as BoldNode).children.first, isA<TextNode>());
      expect(
        ((p.children[1] as BoldNode).children.first as TextNode).text,
        'bold',
      );
      expect((p.children[2] as TextNode).text, ' text');
    });

    test('Parses Header with Bold', () {
      final doc = parser.parse('## Title **Bold**');

      expect(doc.children.length, 1);
      final header = doc.children.first as HeaderNode;
      expect(header.level, 2);

      expect(header.children.length, 2);
      expect((header.children[1] as BoldNode).children.first, isA<TextNode>());
    });
  });
}
