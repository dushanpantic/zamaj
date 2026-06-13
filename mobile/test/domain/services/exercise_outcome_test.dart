import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/services/exercise_outcome.dart';

ExerciseState _replaced() => ExerciseState.replaced(
  substitute: SubstituteExercise(
    name: 'Goblet Squat',
    measurementType: const MeasurementType.bodyweight(),
    plannedValues: PlannedSetValues.bodyweight(
      repTarget: RepTarget.fixed(reps: 10),
    ),
    setCount: 3,
  ),
);

void main() {
  group('ExerciseOutcomes.of', () {
    test('all planned sets logged reads as completed', () {
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.unfinished(),
          executedSetCount: 4,
          plannedSetCount: 4,
        ),
        ExerciseOutcome.completed,
      );
    });

    test('some but not all sets logged reads as partial', () {
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.unfinished(),
          executedSetCount: 2,
          plannedSetCount: 4,
        ),
        ExerciseOutcome.partial,
      );
    });

    test('no sets logged reads as skipped', () {
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.skipped(),
          executedSetCount: 0,
          plannedSetCount: 4,
        ),
        ExerciseOutcome.skipped,
      );
    });

    test(
      'replaced exercise keeps its replaced outcome regardless of counts',
      () {
        expect(
          ExerciseOutcomes.of(
            state: _replaced(),
            executedSetCount: 1,
            plannedSetCount: 4,
          ),
          ExerciseOutcome.replaced,
        );
      },
    );

    test('legacy early-marked-done record self-heals to partial', () {
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.completed(),
          executedSetCount: 2,
          plannedSetCount: 4,
        ),
        ExerciseOutcome.partial,
      );
    });

    test('legacy skipped-with-sets record self-heals to partial', () {
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.skipped(),
          executedSetCount: 2,
          plannedSetCount: 4,
        ),
        ExerciseOutcome.partial,
      );
    });

    test('extra sets beyond plan still read as completed', () {
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.completed(),
          executedSetCount: 5,
          plannedSetCount: 4,
        ),
        ExerciseOutcome.completed,
      );
    });

    test('zero planned sets with zero logged reads as completed', () {
      // Degenerate but well-defined: executed (0) >= planned (0).
      expect(
        ExerciseOutcomes.of(
          state: const ExerciseState.unfinished(),
          executedSetCount: 0,
          plannedSetCount: 0,
        ),
        ExerciseOutcome.completed,
      );
    });

    test('property: derivation follows replaced -> counts precedence', () {
      final rng = Random(20260612);
      for (var i = 0; i < 2000; i++) {
        final planned = rng.nextInt(8); // 0..7
        final executed = rng.nextInt(10); // 0..9
        final replaced = rng.nextBool();
        final state = replaced
            ? _replaced()
            : switch (rng.nextInt(3)) {
                0 => const ExerciseState.unfinished(),
                1 => const ExerciseState.completed(),
                _ => const ExerciseState.skipped(),
              };

        final outcome = ExerciseOutcomes.of(
          state: state,
          executedSetCount: executed,
          plannedSetCount: planned,
        );

        final expected = replaced
            ? ExerciseOutcome.replaced
            : executed >= planned
            ? ExerciseOutcome.completed
            : executed == 0
            ? ExerciseOutcome.skipped
            : ExerciseOutcome.partial;

        expect(
          outcome,
          expected,
          reason: 'planned=$planned executed=$executed replaced=$replaced',
        );
      }
    });
  });
}
