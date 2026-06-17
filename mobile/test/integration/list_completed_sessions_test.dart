// End-to-end coverage for [DriftSessionRepository.listCompletedSessions], the
// read that feeds the exercise-progress aggregator. It must return only ended
// sessions, fully hydrated (snapshot + executed sets), and must stop returning
// a session once it has been deleted — the data-layer half of the
// live-consistency guarantee (AC6).

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
  group('DriftSessionRepository.listCompletedSessions', () {
    late AppDatabase db;
    late DriftProgramRepository programRepo;
    late DriftSessionRepository sessionRepo;
    late String workoutDayId;

    final clock = Clock.fixed(DateTime.utc(2024, 6, 1, 12));

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      programRepo = DriftProgramRepository(db: db, clock: clock);
      sessionRepo = DriftSessionRepository(
        db: db,
        programRepository: programRepo,
        clock: clock,
      );

      final program = await programRepo.createProgram(name: 'P');
      final day = await programRepo.createWorkoutDay(
        programId: program.id,
        name: 'Upper',
      );
      workoutDayId = day.id;
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
    });

    tearDown(() async {
      await db.close();
    });

    test('returns only ended sessions, fully hydrated', () async {
      // An ended session with a logged set.
      final ended = await sessionRepo.startSession(workoutDayId: workoutDayId);
      await sessionRepo.completeSet(
        sessionExerciseId: ended.sessionExercises.single.id,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );
      await sessionRepo.endSession(ended.id);

      // A started-but-not-finished session.
      final active = await sessionRepo.startSession(workoutDayId: workoutDayId);

      final completed = await sessionRepo.listCompletedSessions();

      expect(completed, hasLength(1));
      final session = completed.single;
      expect(session.id, ended.id);
      expect(session.id, isNot(active.id));
      expect(session.endedAt, isNotNull);
      // Snapshot is hydrated with the concrete seeded exercise, not just a
      // non-empty group — a corrupt/partial hydration would fail these.
      final snapshotExercise =
          session.snapshot.workoutDay.exerciseGroups.single.exercises.single;
      expect(snapshotExercise.name, 'Bench');
      expect(
        snapshotExercise.measurementType,
        const MeasurementType.repBased(),
      );
      // Executed sets are hydrated.
      expect(
        session.sessionExercises.single.executedSets.single.actualValues,
        const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );
    });

    test('a deleted session is no longer returned', () async {
      final first = await sessionRepo.startSession(workoutDayId: workoutDayId);
      await sessionRepo.endSession(first.id);
      final second = await sessionRepo.startSession(workoutDayId: workoutDayId);
      await sessionRepo.endSession(second.id);

      expect(await sessionRepo.listCompletedSessions(), hasLength(2));

      await sessionRepo.deleteSession(first.id);

      final remaining = await sessionRepo.listCompletedSessions();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, second.id);
    });
  });
}
