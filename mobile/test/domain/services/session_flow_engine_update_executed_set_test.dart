// Locks the intentional no-`endedAt`-guard behavior of
// [SessionFlowEngine.updateExecutedSet]. Unlike `completeSet` and
// `deleteExecutedSet` — which both throw [ImmutabilityError] on an ended
// session — editing an *executed set's values* must remain permitted after the
// session ends. This is the narrow softening of immutability that post-session
// set correction depends on: values-only, never adding or removing sets, never
// touching the frozen plan snapshot. This test fails if anyone later adds an
// `endedAt` guard to the update path.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    return (repo: repo, engine: engine);
  }

  WorkoutDay buildWorkoutDay() {
    final t = DateTime.utc(2024);
    return WorkoutDay(
      id: 'wd-1',
      programId: 'p-1',
      name: 'Upper',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g1',
          workoutDayId: 'wd-1',
          position: 0,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-bench',
              exerciseGroupId: 'g1',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'ws-bench-0',
                  exerciseId: 'ex-bench',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: PlannedSetValues.repBased(
                    weightKg: 80,
                    repTarget: RepTarget.fixed(reps: 5),
                  ),
                  createdAt: t,
                  updatedAt: t,
                  schemaVersion: 1,
                ),
              ],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
          ],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      ],
      createdAt: t,
      updatedAt: t,
      schemaVersion: 1,
    );
  }

  group('SessionFlowEngine.updateExecutedSet on an ended session', () {
    test(
      'persists the new actual values without throwing ImmutabilityError',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildWorkoutDay());
        final started = await s.engine.startSession(workoutDayId: 'wd-1');
        final benchId = started.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
            .id;

        final afterComplete = await s.engine.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
        );
        final setId = afterComplete.session.sessionExercises
            .firstWhere((e) => e.id == benchId)
            .executedSets
            .single
            .id;

        // End the session: it becomes part of the immutable record.
        final ended = await s.engine.endSession(sessionId: started.session.id);
        expect(ended.session.endedAt, isNotNull);

        // Correcting the logged value must still succeed — no guard.
        final afterEdit = await s.engine.updateExecutedSet(
          executedSetId: setId,
          actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 4),
        );

        final editedSet = afterEdit.session.sessionExercises
            .firstWhere((e) => e.id == benchId)
            .executedSets
            .single;
        expect(
          editedSet.actualValues,
          const ActualSetValues.repBased(weightKg: 82.5, reps: 4),
        );
      },
    );

    test('leaves the frozen planned snapshot unchanged', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildWorkoutDay());
      final started = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = started.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;

      final afterComplete = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      final setId = afterComplete.session.sessionExercises
          .firstWhere((e) => e.id == benchId)
          .executedSets
          .single
          .id;
      await s.engine.endSession(sessionId: started.session.id);

      final afterEdit = await s.engine.updateExecutedSet(
        executedSetId: setId,
        actualValues: const ActualSetValues.repBased(weightKg: 60, reps: 8),
      );

      // The snapshot's planned set is untouched by the actual-value edit.
      final plannedSet = afterEdit
          .session
          .snapshot
          .workoutDay
          .exerciseGroups
          .single
          .exercises
          .single
          .sets
          .single;
      expect(
        plannedSet.plannedValues,
        PlannedSetValues.repBased(
          weightKg: 80,
          repTarget: RepTarget.fixed(reps: 5),
        ),
      );
    });
  });
}
