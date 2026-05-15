import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/in_memory_app_database.dart';

/// `DriftSessionRepository.watchSession` rebuilds the stream emission on
/// updates to any of FIVE related tables. Forgetting any of them in the
/// trigger list would silently drop live-update behavior for that mutation
/// kind — the exact bug the reactive-stream fix exists to prevent. This
/// test pins all five.
void main() {
  test('watchSession emits when each related table is mutated', () async {
    final helper = InMemoryDatabaseHelper();
    await helper.setUp();
    try {
      final programRepo = DriftProgramRepository(db: helper.db);
      final sessionRepo = DriftSessionRepository(
        db: helper.db,
        programRepository: programRepo,
      );

      // Seed a single program/day/exercise with one planned set so we can
      // exercise both the "complete set" and "edit set" paths.
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
        plannedValues: const PlannedSetValues.repBased(
          weightKg: 100,
          reps: 5,
        ),
      );

      // ── sessions table ────────────────────────────────────────────────
      // startSession inserts both a sessions row AND sessionExercises rows,
      // so the very first post-subscription emission can't isolate one
      // table. Start the session BEFORE subscribing, then hit each table
      // with a follow-up mutation.
      final session = await sessionRepo.startSession(workoutDayId: day.id);
      final sessionExId = session.sessionExercises.single.id;

      final emissions = <Session?>[];
      final sub = sessionRepo
          .watchSession(session.id)
          .listen(emissions.add);
      await pumpEventQueue();
      expect(emissions, hasLength(1), reason: 'initial emission');

      // ── sessionNotes table ────────────────────────────────────────────
      await sessionRepo.addSessionNote(sessionId: session.id, body: 'note');
      await pumpEventQueue();
      expect(
        emissions,
        hasLength(2),
        reason: 'sessionNotes update should trigger emission',
      );

      // ── extraWorkItems table ──────────────────────────────────────────
      await sessionRepo.addExtraWork(sessionId: session.id, body: 'extra');
      await pumpEventQueue();
      expect(
        emissions,
        hasLength(3),
        reason: 'extraWorkItems update should trigger emission',
      );

      // ── executedSets table ────────────────────────────────────────────
      final logged = await sessionRepo.completeSet(
        sessionExerciseId: sessionExId,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );
      await pumpEventQueue();
      expect(
        emissions,
        hasLength(4),
        reason: 'executedSets update should trigger emission',
      );

      // ── sessionExercises table ────────────────────────────────────────
      // updateExecutedSet writes to executedSets only, so issue a mutation
      // that hits sessionExercises directly. replaceExercise rewrites the
      // exercise state without touching other tables.
      await sessionRepo.deleteExecutedSet(
        executedSetId:
            logged.sessionExercises.single.executedSets.single.id,
      );
      await pumpEventQueue();
      expect(emissions, hasLength(5));
      await sessionRepo.replaceExercise(
        sessionExerciseId: sessionExId,
        substituteName: 'Goblet Squat',
        substituteMeasurementType: const MeasurementType.repBased(),
      );
      await pumpEventQueue();
      expect(
        emissions,
        hasLength(6),
        reason: 'sessionExercises update should trigger emission',
      );

      // ── sessions table ────────────────────────────────────────────────
      await sessionRepo.endSession(session.id);
      await pumpEventQueue();
      expect(
        emissions,
        hasLength(7),
        reason: 'sessions update should trigger emission',
      );
      expect(emissions.last!.endedAt, isNotNull);

      await sub.cancel();
    } finally {
      await helper.tearDown();
    }
  });

  test('watchSession emits null when the session does not exist', () async {
    final helper = InMemoryDatabaseHelper();
    await helper.setUp();
    try {
      final programRepo = DriftProgramRepository(db: helper.db);
      final sessionRepo = DriftSessionRepository(
        db: helper.db,
        programRepository: programRepo,
      );

      final emissions = <Session?>[];
      final sub = sessionRepo
          .watchSession('missing')
          .listen(emissions.add);
      await pumpEventQueue();
      expect(emissions, [null]);
      await sub.cancel();
    } finally {
      await helper.tearDown();
    }
  });
}
