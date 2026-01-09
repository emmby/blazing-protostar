import 'dart:convert';
import 'dart:io';

import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'util/ast_to_html.dart';

void main() {
  group('CommonMark Spec', () {
    final file = File('test/assets/spec_tests.json');
    if (!file.existsSync()) {
      fail(
        'spec_tests.json not found. Run "curl -o test/assets/spec_tests.json ..."',
      );
    }

    final jsonContent = file.readAsStringSync();
    final List<dynamic> tests = jsonDecode(jsonContent);

    // Filter for MVP features to avoid noise
    final headingsTests = tests
        .where((t) => t['section'] == 'ATX headings')
        .toList();

    // We only enable a subset for now to verify our harness works
    // and demonstrate progress.
    final testCases = headingsTests.take(5);

    for (final testCase in testCases) {
      final markdown = testCase['markdown'] as String;
      final expectedHtml = testCase['html'] as String;
      final exampleId = testCase['example'];

      test('Example $exampleId (Headings)', () {
        final parser = const MarkdownParser();
        final startMd = markdown.replaceAll(
          '→',
          '\t',
        ); // Spec uses special char for tab sometimes

        final doc = parser.parse(startMd);
        final renderer = const AstToHtmlRenderer();
        final actualHtml = renderer.render(doc);

        // Normalize HTML (strip newlines for looser comparison if needed, or stick to strict)
        // Spec usually expects exact match including \n.
        // My parser logic for Headers currently includes the '#' in the text node.
        // Standard CommonMark HTML renderer STRIPS the '#' from the output h tag.
        // So my current implementation will FAIL these tests because I keep the syntax.
        //
        // This confirms my design: My "Editor AST" keeps syntax.
        // To pass "Compliance Tests", my AstToHtmlRenderer needs to describe
        // how to Strip Syntax to match standard HTML output.
        //
        // For this test runner, I will just Print the failure to show I can run them,
        // or I will adjust the Renderer to strip the '#' for headers.

        // Let's TRY to strictly match.
        // But knowing my parser currently keeps '#', I expect failures.
        // That is VALID for an Editor (we want visible syntax), but makes standard testing hard.
        //
        // Strategy:
        // Write the Expectation, let it fail, then decide if we fix the Renderer
        // or if we maintain a "Editor Compliance" separate from "HTML Compliance".
        //
        // Correct approach: The LEXER should identify the syntax range vs content range.
        // My HeaderNode currently has 'children: [TextNode("# Header")]'.
        // Ideally it should be 'children: [TextNode("Header")]'
        // AND 'level: 1'.
        //
        // If I want to verify against spec, I really should parse separation.

        expect(
          actualHtml,
          expectedHtml,
          reason: 'Example $exampleId Failed.\nInput: $markdown',
        );
      });
    }
  });
}
