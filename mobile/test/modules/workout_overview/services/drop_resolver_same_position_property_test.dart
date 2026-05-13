// Validates: dropping an unfinished exercise into the gap immediately
// before or after its current position is a noop (no-op same-position
// semantics, R4).

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drop_resolver.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('beforeIndex(currentIndex) and beforeIndex(currentIndex + 1) both '
      'return Noop for an unfinished dragged exercise', () {
    final rng = Random(46);
    var exercised = 0;

    for (var i = 0; i < iterations; i++) {
      final state = anySessionStateForOverview(rng);
      final groups = ExerciseViewModelAssembler.assemble(state);

      final unfinishedIds = <String>[
        for (final g in groups)
          for (final ex in g.allExercises)
            if (ex.sessionExercise.state is UnfinishedState)
              ex.sessionExercise.id,
      ];
      if (unfinishedIds.isEmpty) continue;

      final draggedId = unfinishedIds[rng.nextInt(unfinishedIds.length)];
      final currentIndex = unfinishedIds.indexOf(draggedId);

      final atCurrent = DropResolver.resolve(
        sessionId: state.session.id,
        groups: groups,
        draggedSessionExerciseId: draggedId,
        target: DropTarget.beforeIndex(currentIndex),
      );
      final afterCurrent = DropResolver.resolve(
        sessionId: state.session.id,
        groups: groups,
        draggedSessionExerciseId: draggedId,
        target: DropTarget.beforeIndex(currentIndex + 1),
      );

      expect(
        atCurrent,
        isA<NoopIntent>(),
        reason:
            'iteration $i: drop at current index '
            '(unfinished=${unfinishedIds.length}, dragged=$draggedId)',
      );
      expect(
        afterCurrent,
        isA<NoopIntent>(),
        reason: 'iteration $i: drop just after current index',
      );
      exercised++;
    }

    expect(
      exercised,
      greaterThan(50),
      reason:
          'expected most iterations to exercise the property; got $exercised',
    );
  });
}
