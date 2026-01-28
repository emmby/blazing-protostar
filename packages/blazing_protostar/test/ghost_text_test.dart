import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ghost Text API', () {
    late MarkdownTextEditingController controller;

    setUp(() {
      controller = MarkdownTextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('ghostText property is initially null', () {
      expect(controller.ghostText, isNull);
    });

    test('setGhostText sets the ghost text', () {
      controller.setGhostText('youtube[video-id]');
      expect(controller.ghostText, equals('youtube[video-id]'));
    });

    test('setGhostText notifies listeners', () {
      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.setGhostText('test');
      expect(notified, isTrue);
    });

    test('clearGhostText clears the ghost text', () {
      controller.setGhostText('test');
      expect(controller.ghostText, isNotNull);

      controller.clearGhostText();
      expect(controller.ghostText, isNull);
    });

    test('clearGhostText notifies listeners', () {
      controller.setGhostText('test');

      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.clearGhostText();
      expect(notified, isTrue);
    });

    test('clearGhostText when already null does not notify', () {
      expect(controller.ghostText, isNull);

      var notified = false;
      controller.addListener(() {
        notified = true;
      });

      controller.clearGhostText();
      expect(notified, isFalse);
    });

    test('setGhostText with null calls clearGhostText', () {
      controller.setGhostText('test');
      expect(controller.ghostText, isNotNull);

      controller.setGhostText(null);
      expect(controller.ghostText, isNull);
    });

    test('setGhostText with empty string calls clearGhostText', () {
      controller.setGhostText('test');
      expect(controller.ghostText, isNotNull);

      controller.setGhostText('');
      expect(controller.ghostText, isNull);
    });
  });

  group('Ghost Text Sanitization', () {
    late MarkdownTextEditingController controller;

    setUp(() {
      controller = MarkdownTextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('sanitizes newlines to spaces', () {
      controller.setGhostText('line1\nline2');
      expect(controller.ghostText, equals('line1 line2'));
    });

    test('sanitizes tabs to spaces', () {
      controller.setGhostText('word1\tword2');
      expect(controller.ghostText, equals('word1 word2'));
    });

    test('sanitizes carriage returns to spaces', () {
      controller.setGhostText('word1\rword2');
      expect(controller.ghostText, equals('word1 word2'));
    });

    test('sanitizes multiple types of whitespace', () {
      controller.setGhostText('word1\n\tword2\rword3');
      expect(controller.ghostText, equals('word1  word2 word3'));
    });

    test('strips control characters', () {
      // ASCII control chars (0x00-0x1F)
      controller.setGhostText('test\x00\x01\x02data');
      expect(controller.ghostText, equals('testdata'));
    });

    test('preserves unicode characters', () {
      controller.setGhostText('Hello 世界');
      expect(controller.ghostText, equals('Hello 世界'));
    });

    test('preserves emoji', () {
      controller.setGhostText('test 🎉 emoji');
      expect(controller.ghostText, equals('test 🎉 emoji'));
    });

    test('preserves regular spaces', () {
      controller.setGhostText('word1 word2 word3');
      expect(controller.ghostText, equals('word1 word2 word3'));
    });

    test('handles complex sanitization scenario', () {
      controller.setGhostText('line1\nline2\t\x00emoji🚀\rend');
      expect(controller.ghostText, equals('line1 line2 emoji🚀 end'));
    });
  });
}
