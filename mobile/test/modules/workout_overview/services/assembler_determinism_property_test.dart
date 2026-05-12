// Validates: ExerciseViewModelAssembler determinism

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('assemble is deterministic across two invocations on the same input',
      () {
    final rng = Random(42);
    for (var i = 0; i < iterations; i++) {
      final state = anySessionStateForOverview(rng);
      final first = ExerciseViewModelAssembler.assemble(state);
      final second = ExerciseViewModelAssembler.assemble(state);
      expect(second, equals(first), reason: 'iteration $i');
    }
  });
}
