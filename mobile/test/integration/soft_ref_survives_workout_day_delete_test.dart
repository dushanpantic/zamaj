import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

void main() {
  group('soft ref: session survives WorkoutDay deletion', () {
    test('getSession returns the full session with snapshot intact after the '
        'source WorkoutDay and its parent Program are deleted', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );

        final rng = Random(0);

        final program = await programRepo.createProgram(name: 'Test Program');

        final workoutDay = await programRepo.createWorkoutDay(
          programId: program.id,
          name: 'Day A',
        );

        await programRepo.createExerciseGroup(
          workoutDayId: workoutDay.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: anyUuidV4(rng),
              exerciseGroupId: '',
              position: 0,
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );

        final session = await sessionRepo.startSession(
          workoutDayId: workoutDay.id,
        );

        final snapshotJsonBefore = session.snapshot.canonicalJson;
        final snapshotHashBefore = session.snapshot.sha256Hash;
        final snapshotWorkoutDayBefore = session.snapshot.workoutDay;

        await programRepo.deleteProgram(program.id);

        final sessionAfter = await sessionRepo.getSession(session.id);

        expect(
          sessionAfter,
          isNotNull,
          reason:
              'Session must still be readable after its source WorkoutDay '
              'is deleted (sessions.workoutDayId is a soft ref with no FK)',
        );

        expect(sessionAfter!.id, equals(session.id));

        expect(
          sessionAfter.workoutDayId,
          equals(workoutDay.id),
          reason: 'workoutDayId soft ref must be preserved as-is',
        );

        expect(
          sessionAfter.snapshot.canonicalJson,
          equals(snapshotJsonBefore),
          reason: 'snapshot canonicalJson must be byte-identical after delete',
        );

        expect(
          sessionAfter.snapshot.sha256Hash,
          equals(snapshotHashBefore),
          reason: 'snapshot sha256Hash must be unchanged after delete',
        );

        expect(
          sessionAfter.snapshot.workoutDay,
          equals(snapshotWorkoutDayBefore),
          reason: 'snapshot workoutDay must be fully readable after delete',
        );

        expect(
          sessionAfter.sessionExercises,
          isNotEmpty,
          reason: 'pre-seeded session exercises must survive the delete',
        );
      } finally {
        await db.close();
      }
    });
  });
}
