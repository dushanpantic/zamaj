// Validates: drop on self is always a noop.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drop_resolver.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('resolve(target: ontoExercise(draggedId)) returns Noop for any '
      'session state and any dragged session-exercise id', () {
    final rng = Random(45);
    for (var i = 0; i < iterations; i++) {
      final state = anySessionStateForOverview(rng);
      final groups = ExerciseViewModelAssembler.assemble(state);
      if (state.session.sessionExercises.isEmpty) continue;

      final draggedId = state
          .session
          .sessionExercises[rng.nextInt(state.session.sessionExercises.length)]
          .id;

      final intent = DropResolver.resolve(
        sessionId: state.session.id,
        groups: groups,
        draggedSessionExerciseId: draggedId,
        target: DropTarget.ontoExercise(draggedId),
      );

      expect(intent, isA<NoopIntent>(), reason: 'iteration $i');
    }
  });
}
