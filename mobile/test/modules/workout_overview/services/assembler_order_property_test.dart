// Validates: Requirement R1 AC2 — assembled flat order matches snapshot
// position order.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('flattened exerciseGroups[*].exercises[*].sessionExercise equals '
      'session.sessionExercises sorted by ascending position', () {
    final rng = Random(43);
    for (var i = 0; i < iterations; i++) {
      final state = anySessionStateForOverview(rng);
      final groups = ExerciseViewModelAssembler.assemble(state);

      final flattened = <SessionExercise>[
        for (final g in groups)
          for (final e in g.allExercises) e.sessionExercise,
      ];
      final expected = List<SessionExercise>.of(state.session.sessionExercises)
        ..sort((a, b) => a.position.compareTo(b.position));

      expect(
        flattened.map((e) => e.id),
        equals(expected.map((e) => e.id)),
        reason: 'iteration $i: order mismatch',
      );
    }
  });
}
