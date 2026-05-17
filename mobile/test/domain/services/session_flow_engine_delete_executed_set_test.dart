import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/log_target.dart';
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

  WorkoutDay buildWorkoutDay({int benchSets = 2, int squatSets = 1}) {
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
                for (var i = 0; i < benchSets; i++)
                  WorkoutSet(
                    id: 'ws-bench-$i',
                    exerciseId: 'ex-bench',
                    position: i,
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
        ExerciseGroup(
          id: 'g2',
          workoutDayId: 'wd-1',
          position: 1,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-squat',
              exerciseGroupId: 'g2',
              position: 0,
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                for (var i = 0; i < squatSets; i++)
                  WorkoutSet(
                    id: 'ws-squat-$i',
                    exerciseId: 'ex-squat',
                    position: i,
                    measurementType: const MeasurementType.repBased(),
                    plannedValues: PlannedSetValues.repBased(
                      weightKg: 100,
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

  group('SessionFlowEngine.deleteExecutedSet', () {
    test('deleting a set on a still-unfinished exercise keeps it unfinished '
        'and rewinds the cursor by one', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildWorkoutDay());
      final started = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = started.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;

      final afterFirst = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      expect(
        afterFirst.openTargets.first,
        LogTarget(sessionExerciseId: benchId, plannedSetIndex: 1),
      );

      final setId = afterFirst.session.sessionExercises
          .firstWhere((e) => e.id == benchId)
          .executedSets
          .single
          .id;

      final afterDelete = await s.engine.deleteExecutedSet(
        executedSetId: setId,
      );
      final bench = afterDelete.session.sessionExercises.firstWhere(
        (e) => e.id == benchId,
      );
      expect(bench.state, const ExerciseState.unfinished());
      expect(bench.executedSets, isEmpty);
      expect(
        afterDelete.openTargets.first,
        LogTarget(sessionExerciseId: benchId, plannedSetIndex: 0),
      );
    });

    test('deleting the last set of a completed exercise reverts it to '
        'unfinished and returns the cursor to it', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildWorkoutDay());
      final started = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = started.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final squatId = started.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-squat')
          .id;

      await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      final afterSecond = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 4),
      );
      final bench = afterSecond.session.sessionExercises.firstWhere(
        (e) => e.id == benchId,
      );
      expect(bench.state, const ExerciseState.completed());
      expect(
        afterSecond.openTargets.first,
        LogTarget(sessionExerciseId: squatId, plannedSetIndex: 0),
      );

      final lastSetId = bench.executedSets.last.id;
      final afterDelete = await s.engine.deleteExecutedSet(
        executedSetId: lastSetId,
      );
      final benchAfter = afterDelete.session.sessionExercises.firstWhere(
        (e) => e.id == benchId,
      );
      expect(benchAfter.state, const ExerciseState.unfinished());
      expect(benchAfter.executedSets, hasLength(1));
      expect(
        afterDelete.openTargets.first,
        LogTarget(sessionExerciseId: benchId, plannedSetIndex: 1),
      );
    });

    test('deleting a set on a replaced exercise that already had extra logged '
        'sets keeps the exercise replaced', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildWorkoutDay(benchSets: 1));
      final started = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = started.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;

      await s.engine.replaceExercise(
        sessionExerciseId: benchId,
        substituteName: 'Cable Fly',
        substituteMeasurementType: const MeasurementType.repBased(),
        substitutePlannedValues: PlannedSetValues.repBased(
          weightKg: 20,
          repTarget: RepTarget.fixed(reps: 12),
        ),
        substituteSetCount: 3,
      );
      await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 20, reps: 12),
      );
      final afterTwo = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 20, reps: 10),
      );
      final benchBefore = afterTwo.session.sessionExercises.firstWhere(
        (e) => e.id == benchId,
      );
      expect(benchBefore.state, isA<ReplacedState>());
      expect(benchBefore.executedSets, hasLength(2));

      final lastId = benchBefore.executedSets.last.id;
      final afterDelete = await s.engine.deleteExecutedSet(
        executedSetId: lastId,
      );
      final benchAfter = afterDelete.session.sessionExercises.firstWhere(
        (e) => e.id == benchId,
      );
      expect(benchAfter.state, isA<ReplacedState>());
      expect(benchAfter.executedSets, hasLength(1));
    });

    test('deleting an unknown executed set throws NotFoundError', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildWorkoutDay());
      await s.engine.startSession(workoutDayId: 'wd-1');
      expect(
        () => s.engine.deleteExecutedSet(executedSetId: 'missing'),
        throwsA(
          isA<NotFoundError>().having(
            (e) => e.entityType,
            'entityType',
            'ExecutedSet',
          ),
        ),
      );
    });

    test(
      'deleting a set on an ended session throws ImmutabilityError',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildWorkoutDay(benchSets: 1, squatSets: 1));
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

        expect(
          () => s.engine.deleteExecutedSet(executedSetId: setId),
          throwsA(isA<ImmutabilityError>()),
        );
      },
    );
  });
}
