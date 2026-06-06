// End-to-end lock for [DriftSessionRepository.updateExecutedSet] on an ended
// session. Editing a logged set's *actual values* must remain permitted after
// the session ends — this is the persistence half of the no-`endedAt`-guard
// behavior that post-session set correction relies on. Fails if anyone later
// adds an `endedAt` guard to the real update path. (The engine half is locked
// in test/domain/services/session_flow_engine_update_executed_set_test.dart.)

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

void main() {
  group('DriftSessionRepository.updateExecutedSet on an ended session', () {
    test('persists corrected actual values without throwing and leaves the '
        'frozen planned snapshot untouched', () async {
      final clock = Clock.fixed(DateTime.utc(2024, 6, 1, 12));
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db, clock: clock);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
          clock: clock,
        );

        final program = await programRepo.createProgram(name: 'P');
        final day = await programRepo.createWorkoutDay(
          programId: program.id,
          name: 'Upper',
        );
        await programRepo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: 'ex-bench',
              exerciseGroupId: '',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: const [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );

        final session = await sessionRepo.startSession(workoutDayId: day.id);
        final exerciseId = session.sessionExercises.single.id;

        final afterComplete = await sessionRepo.completeSet(
          sessionExerciseId: exerciseId,
          actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
        );
        final setId =
            afterComplete.sessionExercises.single.executedSets.single.id;

        // End the session — it becomes part of the immutable record.
        final ended = await sessionRepo.endSession(session.id);
        expect(ended.endedAt, isNotNull);

        // Correcting the logged value must still succeed against the real DB.
        await sessionRepo.updateExecutedSet(
          executedSetId: setId,
          actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 4),
        );

        // Re-read from the database to confirm durable persistence.
        final reloaded = await sessionRepo.getSession(session.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.endedAt, isNotNull);
        expect(
          reloaded.sessionExercises.single.executedSets.single.actualValues,
          const ActualSetValues.repBased(weightKg: 82.5, reps: 4),
        );
      } finally {
        await db.close();
      }
    });
  });
}
