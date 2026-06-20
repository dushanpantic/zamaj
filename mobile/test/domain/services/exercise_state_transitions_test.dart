import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/services/exercise_state_transitions.dart';

void main() {
  group('ExerciseStateTransitions.afterSetLogged', () {
    test('logging the quota-meeting set completes an unfinished exercise', () {
      final next = ExerciseStateTransitions.afterSetLogged(
        const ExerciseState.unfinished(),
        executedSetCount: 3,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.completed());
    });

    test('below quota an unfinished exercise stays unfinished', () {
      final next = ExerciseStateTransitions.afterSetLogged(
        const ExerciseState.unfinished(),
        executedSetCount: 2,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.unfinished());
    });

    test(
      'auto-completion fires only from unfinished (completed unchanged)',
      () {
        final next = ExerciseStateTransitions.afterSetLogged(
          const ExerciseState.completed(),
          executedSetCount: 5,
          plannedSetCount: 3,
        );
        expect(next, const ExerciseState.completed());
      },
    );

    test('a skipped exercise that meets quota stays skipped', () {
      final next = ExerciseStateTransitions.afterSetLogged(
        const ExerciseState.skipped(),
        executedSetCount: 3,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.skipped());
    });
  });

  group('ExerciseStateTransitions.afterSetDeleted', () {
    test('deleting below quota reverts a completed exercise to unfinished', () {
      final next = ExerciseStateTransitions.afterSetDeleted(
        const ExerciseState.completed(),
        executedSetCount: 2,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.unfinished());
    });

    test('deleting while still at quota keeps completion', () {
      final next = ExerciseStateTransitions.afterSetDeleted(
        const ExerciseState.completed(),
        executedSetCount: 3,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.completed());
    });

    test('reverting applies only to completed (unfinished unchanged)', () {
      final next = ExerciseStateTransitions.afterSetDeleted(
        const ExerciseState.unfinished(),
        executedSetCount: 0,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.unfinished());
    });

    test('a skipped exercise below quota stays skipped', () {
      final next = ExerciseStateTransitions.afterSetDeleted(
        const ExerciseState.skipped(),
        executedSetCount: 0,
        plannedSetCount: 3,
      );
      expect(next, const ExerciseState.skipped());
    });
  });
}
