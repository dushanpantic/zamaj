import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

void main() {
  group('snapshot hash mismatch', () {
    late AppDatabase db;
    late DriftProgramRepository programRepo;
    late DriftSessionRepository sessionRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      programRepo = DriftProgramRepository(db: db);
      sessionRepo = DriftSessionRepository(
        db: db,
        programRepository: programRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('getSession raises DeserializationError when snapshotJson is mutated '
        'to desync the stored hash', () async {
      final rng = Random(42);

      final program = await programRepo.createProgram(name: 'Test Program');
      final workoutDay = await programRepo.createWorkoutDay(
        programId: program.id,
        name: 'Test Day',
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

      await db.customStatement(
        'UPDATE sessions SET snapshot_json = ? WHERE id = ?',
        ['{"corrupted":true}', session.id],
      );

      await expectLater(
        sessionRepo.getSession(session.id),
        throwsA(
          isA<DeserializationError>()
              .having((e) => e.field, 'field', 'sessionSnapshot')
              .having((e) => e.discriminator, 'discriminator', 'sha256Hash'),
        ),
      );
    });
  });
}
