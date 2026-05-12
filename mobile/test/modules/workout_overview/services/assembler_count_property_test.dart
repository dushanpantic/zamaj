// Validates: Requirement R1 AC2 — flattened exercise count is preserved.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('flattened exercise count equals session.sessionExercises.length', () {
    final rng = Random(44);
    for (var i = 0; i < iterations; i++) {
      final state = anySessionStateForOverview(rng);
      final groups = ExerciseViewModelAssembler.assemble(state);

      final flatCount = groups.fold<int>(
        0,
        (acc, g) => acc + g.exercises.length,
      );
      expect(
        flatCount,
        equals(state.session.sessionExercises.length),
        reason: 'iteration $i: count mismatch',
      );
    }
  });
}
