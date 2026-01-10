import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/in_memory_backend.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  group('Fuzzing Tests', () {
    const seed = 42; // Fixed seed for reproducibility
    const iterations = 100;

    group('InMemoryBackend Fuzzing', () {
      test('random insert/delete operations maintain consistency', () {
        final random = Random(seed);
        final backend = InMemoryBackend();
        var expectedText = '';

        for (var i = 0; i < iterations; i++) {
          final operation = random.nextInt(3); // 0: insert, 1: delete, 2: both

          if (operation == 0 || expectedText.isEmpty) {
            // Insert random text at random position
            final pos = expectedText.isEmpty
                ? 0
                : random.nextInt(expectedText.length + 1);
            final chars = String.fromCharCodes(
              List.generate(
                random.nextInt(10) + 1,
                (_) => random.nextInt(26) + 97, // a-z
              ),
            );
            backend.insert(pos, chars);
            expectedText =
                expectedText.substring(0, pos) +
                chars +
                expectedText.substring(pos);
          } else if (operation == 1) {
            // Delete random range
            final pos = random.nextInt(expectedText.length);
            final maxCount = expectedText.length - pos;
            final count = random.nextInt(maxCount) + 1;
            backend.delete(pos, count);
            expectedText =
                expectedText.substring(0, pos) +
                expectedText.substring(pos + count);
          } else {
            // Replace: delete then insert at same position
            final pos = random.nextInt(expectedText.length);
            final deleteCount = random.nextInt(expectedText.length - pos) + 1;
            final insertChars = String.fromCharCodes(
              List.generate(
                random.nextInt(5) + 1,
                (_) => random.nextInt(26) + 97,
              ),
            );
            backend.delete(pos, deleteCount);
            expectedText =
                expectedText.substring(0, pos) +
                expectedText.substring(pos + deleteCount);
            backend.insert(pos, insertChars);
            expectedText =
                expectedText.substring(0, pos) +
                insertChars +
                expectedText.substring(pos);
          }

          // Verify after each operation
          expect(
            backend.text,
            expectedText,
            reason: 'Mismatch at iteration $i',
          );
        }
      });

      test('boundary positions are handled correctly', () {
        final random = Random(seed);
        final backend = InMemoryBackend();

        // Start with some text
        backend.insert(0, 'hello world');

        for (var i = 0; i < iterations; i++) {
          // Always insert at boundaries: 0, middle, or end
          final boundary = random.nextInt(3);
          final pos = switch (boundary) {
            0 => 0,
            1 => backend.text.length ~/ 2,
            _ => backend.text.length,
          };

          backend.insert(pos, 'x');
          expect(backend.text.contains('x'), true);

          // Delete the 'x' we just inserted
          final xPos = backend.text.indexOf('x');
          backend.delete(xPos, 1);
        }
      });
    });

    group('Diff Algorithm Fuzzing', () {
      test('random string transformations produce correct backend state', () {
        final random = Random(seed);

        for (var i = 0; i < iterations; i++) {
          final backend = InMemoryBackend();
          final controller = MarkdownTextEditingController(backend: backend);

          // Generate random initial string
          final initialLength = random.nextInt(50) + 1;
          final initial = String.fromCharCodes(
            List.generate(initialLength, (_) => random.nextInt(26) + 97),
          );
          controller.text = initial;
          expect(backend.text, initial, reason: 'Initial text mismatch at $i');

          // Transform to another random string
          final targetLength = random.nextInt(50) + 1;
          final target = String.fromCharCodes(
            List.generate(targetLength, (_) => random.nextInt(26) + 97),
          );
          controller.text = target;
          expect(
            backend.text,
            target,
            reason: 'Target text mismatch at iteration $i',
          );

          controller.dispose();
        }
      });

      test('incremental character-by-character typing', () {
        final random = Random(seed);
        final backend = InMemoryBackend();
        final controller = MarkdownTextEditingController(backend: backend);

        var text = '';
        for (var i = 0; i < iterations; i++) {
          // 80% chance to add, 20% chance to delete
          if (random.nextDouble() < 0.8 || text.isEmpty) {
            final char = String.fromCharCode(random.nextInt(26) + 97);
            final pos = text.isEmpty ? 0 : random.nextInt(text.length + 1);
            text = text.substring(0, pos) + char + text.substring(pos);
          } else {
            final pos = random.nextInt(text.length);
            text = text.substring(0, pos) + text.substring(pos + 1);
          }
          controller.text = text;
          expect(backend.text, text, reason: 'Mismatch at iteration $i');
        }

        controller.dispose();
      });

      test('common prefix/suffix edge cases', () {
        final backend = InMemoryBackend();
        final controller = MarkdownTextEditingController(backend: backend);

        // Same prefix, different suffix
        controller.text = 'abcdef';
        controller.text = 'abcXYZ';
        expect(backend.text, 'abcXYZ');

        // Same suffix, different prefix
        controller.text = 'XYZdef';
        expect(backend.text, 'XYZdef');

        // Same prefix and suffix, different middle
        controller.text = 'XYmmmdef';
        controller.text = 'XYnnnndef';
        expect(backend.text, 'XYnnnndef');

        controller.dispose();
      });

      test('unicode and special characters', () {
        final random = Random(seed);
        final backend = InMemoryBackend();
        final controller = MarkdownTextEditingController(backend: backend);

        final specialChars = ['é', 'ñ', '中', '日', '🎉', '👋', '\n', '\t', ' '];

        for (var i = 0; i < iterations ~/ 2; i++) {
          final length = random.nextInt(20) + 1;
          final text = List.generate(length, (_) {
            if (random.nextDouble() < 0.3) {
              return specialChars[random.nextInt(specialChars.length)];
            }
            return String.fromCharCode(random.nextInt(26) + 97);
          }).join();

          controller.text = text;
          expect(backend.text, text, reason: 'Unicode mismatch at $i');
        }

        controller.dispose();
      });
    });

    group('Stress Tests', () {
      test('large document with many operations', () {
        final random = Random(seed);
        final backend = InMemoryBackend();
        final controller = MarkdownTextEditingController(backend: backend);

        // Start with a large document
        var text = 'x' * 1000;
        controller.text = text;

        for (var i = 0; i < 50; i++) {
          // Random modification
          final pos = random.nextInt(text.length);
          final deleteCount = random.nextInt(20);
          final insertChars = 'y' * random.nextInt(20);

          final safeDeleteCount = deleteCount.clamp(0, text.length - pos);
          text =
              text.substring(0, pos) +
              insertChars +
              text.substring(pos + safeDeleteCount);

          controller.text = text;
          expect(backend.text, text, reason: 'Large doc mismatch at $i');
        }

        controller.dispose();
      });

      test('rapid consecutive changes', () {
        final backend = InMemoryBackend();
        final controller = MarkdownTextEditingController(backend: backend);

        // Simulate very fast typing
        for (var i = 0; i < 100; i++) {
          controller.text = 'a' * i;
          expect(backend.text, 'a' * i);
        }

        controller.dispose();
      });
    });
  });
}
