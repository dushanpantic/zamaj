import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:zamaj/modules/persistence/database/app_database.dart';

import '../support/in_memory_app_database.dart';

const _ts = 1700000000000;
const _sv = 1;

ProgramsCompanion _program(String id) => ProgramsCompanion.insert(
  id: id,
  name: 'P',
  createdAtMs: _ts,
  updatedAtMs: _ts,
  schemaVersion: _sv,
);

WorkoutDaysCompanion _workoutDay(String id, String programId) =>
    WorkoutDaysCompanion.insert(
      id: id,
      programId: programId,
      name: 'WD',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

ExerciseGroupsCompanion _exerciseGroup(String id, String workoutDayId) =>
    ExerciseGroupsCompanion.insert(
      id: id,
      workoutDayId: workoutDayId,
      position: 0,
      kindDiscriminator: 'single',
      kindPayloadJson: '{}',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

ExercisesCompanion _exercise(String id, String exerciseGroupId) =>
    ExercisesCompanion.insert(
      id: id,
      exerciseGroupId: exerciseGroupId,
      position: 0,
      name: 'E',
      measurementTypeDiscriminator: 'repBased',
      measurementTypePayloadJson: '{}',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

WorkoutSetsCompanion _workoutSet(String id, String exerciseId) =>
    WorkoutSetsCompanion.insert(
      id: id,
      exerciseId: exerciseId,
      position: 0,
      plannedValuesDiscriminator: 'repBased',
      plannedValuesPayloadJson: '{"weightKg":60.0,"reps":8}',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

SessionsCompanion _session(String id) => SessionsCompanion.insert(
  id: id,
  workoutDayId: 'wd-soft-ref-$id',
  snapshotJson: '{}',
  snapshotHash: 'a' * 64,
  startedAtMs: _ts,
  createdAtMs: _ts,
  updatedAtMs: _ts,
  schemaVersion: _sv,
);

SessionExercisesCompanion _sessionExercise(String id, String sessionId) =>
    SessionExercisesCompanion.insert(
      id: id,
      sessionId: sessionId,
      position: 0,
      plannedExerciseIdInSnapshot: 'e' * 36,
      stateDiscriminator: 'unfinished',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

ExecutedSetsCompanion _executedSet(String id, String sessionExerciseId) =>
    ExecutedSetsCompanion.insert(
      id: id,
      sessionExerciseId: sessionExerciseId,
      position: 0,
      measurementTypeDiscriminator: 'repBased',
      actualValuesDiscriminator: 'repBased',
      actualValuesPayloadJson: '{"weightKg":60.0,"reps":8}',
      completedAtMs: _ts,
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

SessionNotesCompanion _sessionNote(String id, String sessionId) =>
    SessionNotesCompanion.insert(
      id: id,
      sessionId: sessionId,
      body: 'note',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

ExtraWorkItemsCompanion _extraWorkItem(String id, String sessionId) =>
    ExtraWorkItemsCompanion.insert(
      id: id,
      sessionId: sessionId,
      position: 0,
      body: 'extra',
      createdAtMs: _ts,
      updatedAtMs: _ts,
      schemaVersion: _sv,
    );

String _id(String prefix) => '$prefix-${'x' * (35 - prefix.length)}';

void main() {
  late InMemoryDatabaseHelper helper;
  late AppDatabase db;

  setUp(() async {
    helper = InMemoryDatabaseHelper();
    await helper.setUp();
    db = helper.db;
  });

  tearDown(() async {
    await helper.tearDown();
  });

  group('programs → program_workout_days', () {
    test('insert without parent program fails', () async {
      await expectLater(
        db
            .into(db.programWorkoutDays)
            .insert(
              ProgramWorkoutDaysCompanion.insert(
                programId: _id('ghost-prog'),
                workoutDayId: _id('ghost-wd'),
                position: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting program cascades to program_workout_days', () async {
      final progId = _id('prog-a');
      final wdId = _id('wd-a');
      await db.into(db.programs).insert(_program(progId));
      await db.into(db.workoutDays).insert(_workoutDay(wdId, progId));
      await db
          .into(db.programWorkoutDays)
          .insert(
            ProgramWorkoutDaysCompanion.insert(
              programId: progId,
              workoutDayId: wdId,
              position: 0,
            ),
          );

      await (db.delete(db.programs)..where((t) => t.id.equals(progId))).go();

      final rows = await db.select(db.programWorkoutDays).get();
      expect(rows, isEmpty);
    });
  });

  group('program_workout_days → workout_days', () {
    test('insert with non-existent workout_day fails', () async {
      final progId = _id('prog-b');
      await db.into(db.programs).insert(_program(progId));

      await expectLater(
        db
            .into(db.programWorkoutDays)
            .insert(
              ProgramWorkoutDaysCompanion.insert(
                programId: progId,
                workoutDayId: _id('ghost-wd-b'),
                position: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting workout_day cascades to program_workout_days', () async {
      final progId = _id('prog-c');
      final wdId = _id('wd-c');
      await db.into(db.programs).insert(_program(progId));
      await db.into(db.workoutDays).insert(_workoutDay(wdId, progId));
      await db
          .into(db.programWorkoutDays)
          .insert(
            ProgramWorkoutDaysCompanion.insert(
              programId: progId,
              workoutDayId: wdId,
              position: 0,
            ),
          );

      await (db.delete(db.workoutDays)..where((t) => t.id.equals(wdId))).go();

      final rows = await db.select(db.programWorkoutDays).get();
      expect(rows, isEmpty);
    });
  });

  group('workout_days → exercise_groups', () {
    test('insert without parent workout_day fails', () async {
      await expectLater(
        db
            .into(db.exerciseGroups)
            .insert(_exerciseGroup(_id('eg-ghost'), _id('wd-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting workout_day cascades to exercise_groups', () async {
      final progId = _id('prog-d');
      final wdId = _id('wd-d');
      final egId = _id('eg-d');
      await db.into(db.programs).insert(_program(progId));
      await db.into(db.workoutDays).insert(_workoutDay(wdId, progId));
      await db.into(db.exerciseGroups).insert(_exerciseGroup(egId, wdId));

      await (db.delete(db.workoutDays)..where((t) => t.id.equals(wdId))).go();

      final rows = await db.select(db.exerciseGroups).get();
      expect(rows, isEmpty);
    });
  });

  group('exercise_groups → exercises', () {
    test('insert without parent exercise_group fails', () async {
      await expectLater(
        db
            .into(db.exercises)
            .insert(_exercise(_id('ex-ghost'), _id('eg-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting exercise_group cascades to exercises', () async {
      final progId = _id('prog-e');
      final wdId = _id('wd-e');
      final egId = _id('eg-e');
      final exId = _id('ex-e');
      await db.into(db.programs).insert(_program(progId));
      await db.into(db.workoutDays).insert(_workoutDay(wdId, progId));
      await db.into(db.exerciseGroups).insert(_exerciseGroup(egId, wdId));
      await db.into(db.exercises).insert(_exercise(exId, egId));

      await (db.delete(
        db.exerciseGroups,
      )..where((t) => t.id.equals(egId))).go();

      final rows = await db.select(db.exercises).get();
      expect(rows, isEmpty);
    });
  });

  group('exercises → sets', () {
    test('insert without parent exercise fails', () async {
      await expectLater(
        db
            .into(db.workoutSets)
            .insert(_workoutSet(_id('ws-ghost'), _id('ex-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting exercise cascades to sets', () async {
      final progId = _id('prog-f');
      final wdId = _id('wd-f');
      final egId = _id('eg-f');
      final exId = _id('ex-f');
      final wsId = _id('ws-f');
      await db.into(db.programs).insert(_program(progId));
      await db.into(db.workoutDays).insert(_workoutDay(wdId, progId));
      await db.into(db.exerciseGroups).insert(_exerciseGroup(egId, wdId));
      await db.into(db.exercises).insert(_exercise(exId, egId));
      await db.into(db.workoutSets).insert(_workoutSet(wsId, exId));

      await (db.delete(db.exercises)..where((t) => t.id.equals(exId))).go();

      final rows = await db.select(db.workoutSets).get();
      expect(rows, isEmpty);
    });
  });

  group('sessions → session_exercises', () {
    test('insert without parent session fails', () async {
      await expectLater(
        db
            .into(db.sessionExercises)
            .insert(_sessionExercise(_id('se-ghost'), _id('sess-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting session cascades to session_exercises', () async {
      final sessId = _id('sess-g');
      final seId = _id('se-g');
      await db.into(db.sessions).insert(_session(sessId));
      await db.into(db.sessionExercises).insert(_sessionExercise(seId, sessId));

      await (db.delete(db.sessions)..where((t) => t.id.equals(sessId))).go();

      final rows = await db.select(db.sessionExercises).get();
      expect(rows, isEmpty);
    });
  });

  group('session_exercises → executed_sets', () {
    test('insert without parent session_exercise fails', () async {
      await expectLater(
        db
            .into(db.executedSets)
            .insert(_executedSet(_id('es-ghost'), _id('se-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting session_exercise cascades to executed_sets', () async {
      final sessId = _id('sess-h');
      final seId = _id('se-h');
      final esId = _id('es-h');
      await db.into(db.sessions).insert(_session(sessId));
      await db.into(db.sessionExercises).insert(_sessionExercise(seId, sessId));
      await db.into(db.executedSets).insert(_executedSet(esId, seId));

      await (db.delete(
        db.sessionExercises,
      )..where((t) => t.id.equals(seId))).go();

      final rows = await db.select(db.executedSets).get();
      expect(rows, isEmpty);
    });
  });

  group('sessions → session_notes', () {
    test('insert without parent session fails', () async {
      await expectLater(
        db
            .into(db.sessionNotes)
            .insert(_sessionNote(_id('sn-ghost'), _id('sess-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting session cascades to session_notes', () async {
      final sessId = _id('sess-i');
      final snId = _id('sn-i');
      await db.into(db.sessions).insert(_session(sessId));
      await db.into(db.sessionNotes).insert(_sessionNote(snId, sessId));

      await (db.delete(db.sessions)..where((t) => t.id.equals(sessId))).go();

      final rows = await db.select(db.sessionNotes).get();
      expect(rows, isEmpty);
    });
  });

  group('sessions → extra_work_items', () {
    test('insert without parent session fails', () async {
      await expectLater(
        db
            .into(db.extraWorkItems)
            .insert(_extraWorkItem(_id('ew-ghost'), _id('sess-ghost'))),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting session cascades to extra_work_items', () async {
      final sessId = _id('sess-j');
      final ewId = _id('ew-j');
      await db.into(db.sessions).insert(_session(sessId));
      await db.into(db.extraWorkItems).insert(_extraWorkItem(ewId, sessId));

      await (db.delete(db.sessions)..where((t) => t.id.equals(sessId))).go();

      final rows = await db.select(db.extraWorkItems).get();
      expect(rows, isEmpty);
    });
  });
}
