import 'dart:convert';
import 'dart:io';

import 'package:blazing_protostar/src/features/editor/domain/parsing/markdown_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'util/ast_to_html.dart';

void main() {
  group('Generic Directive Parsing', () {
    final file = File('test/assets/generic_directive_tests.json');
    if (!file.existsSync()) {
      fail('generic_directive_tests.json not found.');
    }

    final jsonContent = file.readAsStringSync();
    final List<dynamic> tests = jsonDecode(jsonContent);

    for (final testCase in tests) {
      final userInput = testCase['markdown'] as String;
      final expectedHtml = testCase['html'] as String;
      final section = testCase['section'] as String;

      test('$section: $userInput', () {
        final parser = const MarkdownParser();
        final doc = parser.parse(userInput);
        final renderer = const AstToHtmlRenderer();
        final actualHtml = renderer.render(doc);

        expect(
          actualHtml.trim(), // Trim to avoid minor newline diffs
          expectedHtml.trim(),
          reason: 'Input: $userInput',
        );
      });
    }
  });
}
