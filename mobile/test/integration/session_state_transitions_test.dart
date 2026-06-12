// Pins AC3: exercise auto-complete/revert through the real Drift transaction.
// Logging the quota-meeting set auto-completes an unfinished exercise; deleting
// a set back below quota reverts it to unfinished. The repo delegates the rule
// to the domain ExerciseStateTransitions — this test guards the end-to-end
// behavior across that delegation.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart'
    hide WorkoutSet;
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

domain.Exercise _exerciseWithTwoSets() {
  WorkoutSet set(int i) => WorkoutSet(
    id: 'set-$i',
    exerciseId: 'planned-exercise',
    position: i,
    measurementType: const MeasurementType.repBased(),
    plannedValues: PlannedSetValues.repBased(
      weightKg: 100,
      repTarget: RepTarget.fixed(reps: 5),
    ),
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    schemaVersion: 1,
  );
  return domain.Exercise(
    id: 'planned-exercise',
    exerciseGroupId: '',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    sets: [set(0), set(1)],
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    schemaVersion: 1,
  );
}

void main() {
  group('DriftSessionRepository state transitions', () {
    test('logging the quota-meeting set auto-completes; deleting below quota '
        'reverts to unfinished', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );

        final program = await programRepo.createProgram(name: 'P');
        final workoutDay = await programRepo.createWorkoutDay(
          programId: program.id,
          name: 'D',
        );
        await programRepo.createExerciseGroup(
          workoutDayId: workoutDay.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [_exerciseWithTwoSets()],
        );

        final session = await sessionRepo.startSession(
          workoutDayId: workoutDay.id,
        );
        final seId = session.sessionExercises.single.id;

        // First set: still below quota → unfinished.
        final afterFirst = await sessionRepo.completeSet(
          sessionExerciseId: seId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
        expect(
          afterFirst.sessionExercises.single.state,
          isA<UnfinishedState>(),
        );

        // Second set: reaches quota → completed.
        final afterSecond = await sessionRepo.completeSet(
          sessionExerciseId: seId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
        expect(
          afterSecond.sessionExercises.single.state,
          isA<CompletedState>(),
        );

        // Delete one set: drops below quota → reverts to unfinished.
        final lastSetId =
            afterSecond.sessionExercises.single.executedSets.last.id;
        final afterDelete = await sessionRepo.deleteExecutedSet(
          executedSetId: lastSetId,
        );
        expect(
          afterDelete.sessionExercises.single.state,
          isA<UnfinishedState>(),
        );
      } finally {
        await db.close();
      }
    });

    test('deleting a set from a still-at-quota completed exercise keeps it '
        'completed', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );

        final program = await programRepo.createProgram(name: 'P');
        final workoutDay = await programRepo.createWorkoutDay(
          programId: program.id,
          name: 'D',
        );
        // One planned set, but log three; deleting one leaves two — still at or
        // above quota, so completion is retained.
        await programRepo.createExerciseGroup(
          workoutDayId: workoutDay.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: 'planned-exercise',
              exerciseGroupId: '',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'set-0',
                  exerciseId: 'planned-exercise',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: PlannedSetValues.repBased(
                    weightKg: 100,
                    repTarget: RepTarget.fixed(reps: 5),
                  ),
                  createdAt: DateTime.utc(2024),
                  updatedAt: DateTime.utc(2024),
                  schemaVersion: 1,
                ),
              ],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );

        final session = await sessionRepo.startSession(
          workoutDayId: workoutDay.id,
        );
        final seId = session.sessionExercises.single.id;

        for (var i = 0; i < 3; i++) {
          await sessionRepo.completeSet(
            sessionExerciseId: seId,
            actualValues: const ActualSetValues.repBased(
              weightKg: 100,
              reps: 5,
            ),
          );
        }

        final loaded = await sessionRepo.getSession(session.id);
        final completed = loaded!.sessionExercises.single;
        expect(completed.state, isA<CompletedState>());

        final afterDelete = await sessionRepo.deleteExecutedSet(
          executedSetId: completed.executedSets.last.id,
        );
        // Two remaining ≥ quota of one → stays completed.
        expect(
          afterDelete.sessionExercises.single.state,
          isA<CompletedState>(),
        );
      } finally {
        await db.close();
      }
    });
  });
}
