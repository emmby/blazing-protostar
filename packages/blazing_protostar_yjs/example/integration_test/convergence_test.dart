import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:blazing_protostar_yjs_example/dual_editor_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('CRDT Convergence Tests', () {
    testWidgets('two editors converge after random operations', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DualEditorTest()));

      // Wait for Yjs to initialize
      await tester.pumpAndSettle();

      // Find the test widget state
      final state = tester.state<DualEditorTestState>(
        find.byType(DualEditorTest),
      );

      // Run the convergence fuzz test
      final converged = await state.runConvergenceFuzzTest(
        iterations: 50,
        seed: 42,
        onStep: () => tester.pump(),
      );

      // Pump to update UI
      await tester.pumpAndSettle();

      // Verify convergence
      expect(converged, isTrue, reason: 'Editors should converge to same text');

      // Also verify by reading controller text directly
      expect(state.controller1.text, equals(state.controller2.text));
    });

    testWidgets('convergence with many iterations', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DualEditorTest()));

      await tester.pumpAndSettle();

      final state = tester.state<DualEditorTestState>(
        find.byType(DualEditorTest),
      );

      // Run with more iterations for stress testing
      final converged = await state.runConvergenceFuzzTest(
        iterations: 100,
        seed: 123,
        onStep: () => tester.pump(),
      );

      await tester.pumpAndSettle();

      expect(converged, isTrue);
      expect(state.controller1.text, equals(state.controller2.text));
    });

    testWidgets('convergence with different random seeds', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DualEditorTest()));

      await tester.pumpAndSettle();

      final state = tester.state<DualEditorTestState>(
        find.byType(DualEditorTest),
      );

      // Test with multiple different seeds
      for (final seed in [1, 42, 999, 12345]) {
        // Reset editors
        state.controller1.text = '';
        state.controller2.text = '';
        await tester.pumpAndSettle();

        final converged = await state.runConvergenceFuzzTest(
          iterations: 30,
          seed: seed,
          onStep: () => tester.pump(),
        );

        await tester.pumpAndSettle();

        expect(
          converged,
          isTrue,
          reason: 'Editors should converge with seed $seed',
        );
        expect(state.controller1.text, equals(state.controller2.text));
      }
    });
  });
}
