import 'package:flutter_test/flutter_test.dart';
import 'package:blazing_protostar/src/features/editor/domain/backends/in_memory_backend.dart';
import 'package:blazing_protostar/src/features/editor/presentation/markdown_text_editing_controller.dart';

void main() {
  group('Phase 2: Bridge Architecture Logic', () {
    test('Controller initializes with initialText via default backend', () {
      final controller = MarkdownTextEditingController(text: 'Initial');
      expect(controller.text, 'Initial');
    });

    test('Updating controller text updates the backend', () {
      final backend = InMemoryBackend();
      final controller = MarkdownTextEditingController(backend: backend);

      controller.text = 'New Text';
      expect(backend.text, 'New Text');
    });

    test(
      'Updating backend text updates the controller (Remote Sync simulation)',
      () {
        final backend = InMemoryBackend(initialText: 'Old');
        final controller = MarkdownTextEditingController(backend: backend);

        expect(controller.text, 'Old');

        // Simulate remote change: delete 'Old', insert 'Remote Change'
        backend.delete(0, 3);
        backend.insert(0, 'Remote Change');
        expect(controller.text, 'Remote Change');
      },
    );

    test('Blocks stay in sync when backend updates', () {
      final backend = InMemoryBackend(initialText: 'First');
      final controller = MarkdownTextEditingController(backend: backend);

      expect(controller.blocks.first.text, 'First');

      // Simulate remote change: delete 'First', insert '# Header'
      backend.delete(0, 5);
      backend.insert(0, '# Header');
      expect(controller.blocks.first.type, 'header');
      expect(controller.blocks.first.text, '# Header');
    });

    test('InMemoryBackend insert and delete operations', () {
      final backend = InMemoryBackend(initialText: 'hello');

      backend.insert(5, ' world');
      expect(backend.text, 'hello world');

      backend.delete(5, 6);
      expect(backend.text, 'hello');

      backend.delete(0, 2);
      expect(backend.text, 'llo');

      backend.insert(0, 'he');
      expect(backend.text, 'hello');

      // Mid-string insertion
      backend.insert(2, 'yyy');
      expect(backend.text, 'heyyyllo');

      // Mid-string deletion
      backend.delete(2, 3);
      expect(backend.text, 'hello');
    });
  });
}
