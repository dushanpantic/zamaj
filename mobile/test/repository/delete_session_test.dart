import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/in_memory_app_database.dart';

void main() {
  test(
    'deleteSession removes the session and cascades through every child table',
    () async {
      final helper = InMemoryDatabaseHelper();
      await helper.setUp();
      try {
        final programRepo = DriftProgramRepository(db: helper.db);
        final sessionRepo = DriftSessionRepository(
          db: helper.db,
          programRepository: programRepo,
        );

        final program = await programRepo.createProgram(name: 'P');
        final day = await programRepo.createWorkoutDay(
          programId: program.id,
          name: 'Day',
        );
        await programRepo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: '11111111-1111-1111-1111-111111111111',
              exerciseGroupId: '',
              position: 0,
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: const [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );
        final reloaded = await programRepo.getWorkoutDay(day.id);
        final exerciseId = reloaded!.exerciseGroups.single.exercises.single.id;
        await programRepo.createSet(
          exerciseId: exerciseId,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 5),
          ),
        );

        // Touch every child table so a missing cascade would leave orphans.
        final session = await sessionRepo.startSession(workoutDayId: day.id);
        await sessionRepo.completeSet(
          sessionExerciseId: session.sessionExercises.single.id,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
        await sessionRepo.addSessionNote(
          sessionId: session.id,
          body: 'felt strong',
        );
        await sessionRepo.addExtraWork(
          sessionId: session.id,
          body: 'plus 10 min walk',
        );
        await sessionRepo.endSession(session.id);

        await sessionRepo.deleteSession(session.id);

        final db = helper.db;
        expect(await db.select(db.sessions).get(), isEmpty);
        expect(await db.select(db.sessionExercises).get(), isEmpty);
        expect(await db.select(db.executedSets).get(), isEmpty);
        expect(await db.select(db.sessionNotes).get(), isEmpty);
        expect(await db.select(db.extraWorkItems).get(), isEmpty);

        // Program template must be untouched.
        expect(await db.select(db.programs).get(), hasLength(1));
        expect(await db.select(db.workoutDays).get(), hasLength(1));
        expect(await db.select(db.exercises).get(), hasLength(1));
        expect(await db.select(db.workoutSets).get(), hasLength(1));
      } finally {
        await helper.tearDown();
      }
    },
  );

  test('deleteSession on a missing id throws NotFoundError', () async {
    final helper = InMemoryDatabaseHelper();
    await helper.setUp();
    try {
      final programRepo = DriftProgramRepository(db: helper.db);
      final sessionRepo = DriftSessionRepository(
        db: helper.db,
        programRepository: programRepo,
      );

      await expectLater(
        () => sessionRepo.deleteSession('does-not-exist'),
        throwsA(
          isA<NotFoundError>()
              .having((e) => e.entityType, 'entityType', 'Session')
              .having((e) => e.id, 'id', 'does-not-exist'),
        ),
      );
    } finally {
      await helper.tearDown();
    }
  });
}
