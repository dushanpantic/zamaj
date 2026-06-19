import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

const _libraryId = '11111111-1111-4111-8111-111111111111';

domain.Exercise _exercise(String name) => domain.Exercise(
  id: '',
  exerciseGroupId: '',
  position: 0,
  name: name,
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: const [],
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  schemaVersion: 1,
);

AddedExercisePlan _plan({String? libraryExerciseId}) => AddedExercisePlan(
  name: 'Added Curl',
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 60,
    repTarget: RepTarget.fixed(reps: 12),
  ),
  setCount: 3,
  libraryExerciseId: libraryExerciseId,
);

void main() {
  group('DriftSessionRepository.addExercise', () {
    Future<({DriftSessionRepository repo, String sessionId, AppDatabase db})>
    startedSession() async {
      final db = AppDatabase(NativeDatabase.memory());
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
        exercises: [_exercise('Squat')],
      );
      final session = await sessionRepo.startSession(workoutDayId: workoutDay.id);
      return (repo: sessionRepo, sessionId: session.id, db: db);
    }

    test('persists an added exercise: appended after max position, synthetic '
        '36-char id, addedPlan rehydrated, unfinished, snapshot untouched',
        () async {
      final s = await startedSession();
      try {
        final before = (await s.repo.getSession(s.sessionId))!;
        final hashBefore = before.snapshot.sha256Hash;
        final maxPositionBefore = before.sessionExercises
            .map((e) => e.position)
            .reduce((a, b) => a > b ? a : b);

        final session = await s.repo.addExercise(
          sessionId: s.sessionId,
          plan: _plan(libraryExerciseId: _libraryId),
        );

        final added = session.sessionExercises.last;
        expect(session.sessionExercises, hasLength(2));
        expect(added.state, isA<UnfinishedState>());
        expect(added.addedPlan?.name, 'Added Curl');
        expect(added.addedPlan?.libraryExerciseId, _libraryId);
        expect(added.position, greaterThan(maxPositionBefore));
        expect(added.plannedExerciseIdInSnapshot.length, 36);
        expect(session.snapshot.sha256Hash, hashBefore);

        // Reloads from disk identically (added_plan_json round-trips).
        final reloaded = (await s.repo.getSession(s.sessionId))!;
        expect(reloaded.sessionExercises.last.addedPlan?.name, 'Added Curl');
      } finally {
        await s.db.close();
      }
    });

    test('addedPlan rehydrates regardless of state (survives completion) and '
        'logging persists executed sets', () async {
      final s = await startedSession();
      try {
        final session = await s.repo.addExercise(
          sessionId: s.sessionId,
          plan: _plan(),
        );
        final addedId = session.sessionExercises.last.id;

        // Log its full quota (3) so it auto-completes.
        for (var i = 0; i < 3; i++) {
          await s.repo.completeSet(
            sessionExerciseId: addedId,
            actualValues: const ActualSetValues.repBased(
              weightKg: 60,
              reps: 12,
            ),
          );
        }

        final reloaded = (await s.repo.getSession(s.sessionId))!;
        final added = reloaded.sessionExercises.firstWhere(
          (e) => e.id == addedId,
        );
        expect(added.state, isA<CompletedState>());
        // The inline plan still rehydrates after the state transition.
        expect(added.addedPlan?.name, 'Added Curl');
        expect(added.executedSets, hasLength(3));
      } finally {
        await s.db.close();
      }
    });
  });

  test('v13→v14 migration adds added_plan_json without data loss', () async {
    final file = File(
      '${Directory.systemTemp.path}/migration_added_plan_'
      '${DateTime.now().microsecondsSinceEpoch}.db',
    );
    try {
      final rawDb = raw.sqlite3.open(file.path);
      // v13 session_exercises schema (no added_plan_json yet).
      rawDb.execute('''
        CREATE TABLE session_exercises (
          id TEXT NOT NULL PRIMARY KEY,
          session_id TEXT NOT NULL,
          position INTEGER NOT NULL,
          planned_exercise_id_in_snapshot TEXT NOT NULL,
          state_discriminator TEXT NOT NULL,
          substitute_payload_json TEXT,
          superset_tag TEXT,
          created_at_ms INTEGER NOT NULL,
          updated_at_ms INTEGER NOT NULL,
          schema_version INTEGER NOT NULL,
          UNIQUE (session_id, position)
        )
      ''');
      rawDb.execute(
        'INSERT INTO session_exercises VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'se--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
          'sess-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
          0,
          'planned-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
          'unfinished',
          null,
          null,
          1700000000000,
          1700000000000,
          9,
        ],
      );
      rawDb.execute('PRAGMA user_version = 13');
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();

      // The new column exists and the legacy row defaults to null, intact.
      final row = await db
          .customSelect(
            'SELECT added_plan_json, state_discriminator FROM session_exercises '
            'WHERE id = ?',
            variables: [
              const Variable<String>('se--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'),
            ],
          )
          .getSingle();
      expect(row.read<String?>('added_plan_json'), isNull);
      expect(row.read<String>('state_discriminator'), 'unfinished');

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });
}
