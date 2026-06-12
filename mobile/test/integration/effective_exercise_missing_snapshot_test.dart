// Pins AC2: a session-exercise whose planned exercise is absent from the
// immutable snapshot must raise NotFoundError on the mutation path, replacing
// the Drift repo's former silent "planned set count = 0" degradation (which let
// deleteExecutedSet skip the completed→unfinished revert on corrupt data).

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

void main() {
  group('DriftSessionRepository missing-snapshot hardening', () {
    test('deleteExecutedSet throws NotFoundError when the planned exercise is '
        'absent from the snapshot (no silent set-count-0)', () async {
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
          exercises: [
            domain.Exercise(
              id: 'planned-exercise',
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

        final session = await sessionRepo.startSession(
          workoutDayId: workoutDay.id,
        );
        final sessionExerciseId = session.sessionExercises.single.id;

        // Log one set (snapshot still intact) so there is an executed set to
        // delete and the exercise auto-completes.
        final afterLog = await sessionRepo.completeSet(
          sessionExerciseId: sessionExerciseId,
          actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
        );
        final executedSetId =
            afterLog.sessionExercises.single.executedSets.single.id;

        // Corrupt the snapshot reference: point the row at a planned id that is
        // not present in the immutable snapshot.
        await (db.update(
          db.sessionExercises,
        )..where((t) => t.id.equals(sessionExerciseId))).write(
          const SessionExercisesCompanion(
            plannedExerciseIdInSnapshot: Value(
              'ffffffff-ffff-4fff-8fff-ffffffffffff',
            ),
          ),
        );

        await expectLater(
          sessionRepo.deleteExecutedSet(executedSetId: executedSetId),
          throwsA(isA<NotFoundError>()),
        );
      } finally {
        await db.close();
      }
    });
  });
}
