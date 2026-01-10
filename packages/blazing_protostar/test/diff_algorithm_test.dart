import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/in_memory_backend.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  group('Diff Algorithm Tests', () {
    late InMemoryBackend backend;
    late MarkdownTextEditingController controller;

    setUp(() {
      backend = InMemoryBackend();
      controller = MarkdownTextEditingController(backend: backend);
    });

    tearDown(() {
      controller.dispose();
    });

    group('Basic Insert Operations', () {
      test('insert at start', () {
        controller.text = 'hello';
        controller.text = 'world hello';
        expect(backend.text, 'world hello');
      });

      test('insert at end', () {
        controller.text = 'hello';
        controller.text = 'hello world';
        expect(backend.text, 'hello world');
      });

      test('insert in middle', () {
        controller.text = 'helo';
        controller.text = 'hello';
        expect(backend.text, 'hello');
      });

      test('insert single character', () {
        controller.text = 'ab';
        controller.text = 'acb';
        expect(backend.text, 'acb');
      });
    });

    group('Basic Delete Operations', () {
      test('delete from start', () {
        controller.text = 'hello world';
        controller.text = 'world';
        expect(backend.text, 'world');
      });

      test('delete from end', () {
        controller.text = 'hello world';
        controller.text = 'hello';
        expect(backend.text, 'hello');
      });

      test('delete from middle', () {
        controller.text = 'hello';
        controller.text = 'helo';
        expect(backend.text, 'helo');
      });

      test('delete single character', () {
        controller.text = 'abc';
        controller.text = 'ac';
        expect(backend.text, 'ac');
      });
    });

    group('Replace Operations', () {
      test('replace single character', () {
        controller.text = 'abc';
        controller.text = 'aXc';
        expect(backend.text, 'aXc');
      });

      test('replace word in middle', () {
        controller.text = 'hello world today';
        controller.text = 'hello there today';
        expect(backend.text, 'hello there today');
      });

      test('replace entire text', () {
        controller.text = 'hello';
        controller.text = 'world';
        expect(backend.text, 'world');
      });

      test('replace with longer text', () {
        controller.text = 'abc';
        controller.text = 'aXYZc';
        expect(backend.text, 'aXYZc');
      });

      test('replace with shorter text', () {
        controller.text = 'aXYZc';
        controller.text = 'abc';
        expect(backend.text, 'abc');
      });
    });

    group('Edge Cases', () {
      test('empty to non-empty', () {
        controller.text = '';
        controller.text = 'hello';
        expect(backend.text, 'hello');
      });

      test('non-empty to empty', () {
        controller.text = 'hello';
        controller.text = '';
        expect(backend.text, '');
      });

      test('no change - identical strings', () {
        controller.text = 'hello';
        controller.text = 'hello';
        expect(backend.text, 'hello');
      });

      test('repeated characters - add one', () {
        controller.text = 'aaa';
        controller.text = 'aaaa';
        expect(backend.text, 'aaaa');
      });

      test('repeated characters - remove one', () {
        controller.text = 'aaaa';
        controller.text = 'aaa';
        expect(backend.text, 'aaa');
      });

      test('whitespace only', () {
        controller.text = '   ';
        controller.text = '    ';
        expect(backend.text, '    ');
      });

      test('newlines', () {
        controller.text = 'a\nb';
        controller.text = 'a\n\nb';
        expect(backend.text, 'a\n\nb');
      });
    });

    group('Multi-line Text', () {
      test('insert line in middle', () {
        controller.text = 'line1\nline3';
        controller.text = 'line1\nline2\nline3';
        expect(backend.text, 'line1\nline2\nline3');
      });

      test('delete line from middle', () {
        controller.text = 'line1\nline2\nline3';
        controller.text = 'line1\nline3';
        expect(backend.text, 'line1\nline3');
      });

      test('replace line', () {
        controller.text = 'line1\nline2\nline3';
        controller.text = 'line1\nmodified\nline3';
        expect(backend.text, 'line1\nmodified\nline3');
      });
    });

    group('Unicode and Emoji', () {
      test('insert unicode character', () {
        controller.text = 'hello';
        controller.text = 'héllo';
        expect(backend.text, 'héllo');
      });

      test('insert emoji', () {
        controller.text = 'hello';
        controller.text = 'hello 👋';
        expect(backend.text, 'hello 👋');
      });

      test('emoji in middle', () {
        controller.text = 'ab';
        controller.text = 'a🎉b';
        expect(backend.text, 'a🎉b');
      });

      test('replace with emoji', () {
        controller.text = 'hello';
        controller.text = '👋';
        expect(backend.text, '👋');
      });

      test('multiple emojis', () {
        controller.text = 'abc';
        controller.text = 'a🎉🎊c';
        expect(backend.text, 'a🎉🎊c');
      });
    });

    group('Large Text Operations', () {
      test('large insert (paste)', () {
        controller.text = 'start end';
        final largeText = 'x' * 1000;
        controller.text = 'start $largeText end';
        expect(backend.text, 'start $largeText end');
      });

      test('large delete', () {
        final largeText = 'x' * 1000;
        controller.text = 'start $largeText end';
        controller.text = 'start end';
        expect(backend.text, 'start end');
      });
    });

    group('Sequential Operations', () {
      test('multiple sequential inserts', () {
        controller.text = 'a';
        controller.text = 'ab';
        controller.text = 'abc';
        controller.text = 'abcd';
        expect(backend.text, 'abcd');
      });

      test('multiple sequential deletes', () {
        controller.text = 'abcd';
        controller.text = 'abc';
        controller.text = 'ab';
        controller.text = 'a';
        expect(backend.text, 'a');
      });

      test('mixed operations', () {
        controller.text = 'hello';
        controller.text = 'hello world';
        controller.text = 'hi world';
        controller.text = 'hi there';
        expect(backend.text, 'hi there');
      });
    });
  });
}
