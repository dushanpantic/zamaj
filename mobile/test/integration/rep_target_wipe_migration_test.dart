import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/persistence/database/app_database.dart';

const _ts = 1700000000000;

void main() {
  test(
    'v6→v7 migration wipes every domain table (rep-target rollout)',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/rep_target_wipe_migration_test_'
        '${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final rawDb = raw.sqlite3.open(file.path);
        _createV6Schema(rawDb);
        _seedRowInEveryTable(rawDb);
        rawDb.execute('PRAGMA user_version = 6');
        rawDb.close();

        final migratedDb = AppDatabase(NativeDatabase(file));
        // Touching the database opens it and runs migrations.
        await migratedDb.customSelect('SELECT 1').get();

        Future<int> count(String table) async {
          final rows = await migratedDb
              .customSelect('SELECT COUNT(*) AS c FROM $table')
              .get();
          return rows.single.read<int>('c');
        }

        for (final table in const [
          'programs',
          'workout_days',
          'exercise_groups',
          'exercises',
          'sets',
          'program_workout_days',
          'sessions',
          'session_exercises',
          'executed_sets',
          'session_notes',
          'extra_work_items',
        ]) {
          expect(await count(table), 0, reason: '$table should be empty');
        }

        // Database still functions for fresh writes after the wipe.
        final programs = await migratedDb.select(migratedDb.programs).get();
        expect(programs, isEmpty);

        await migratedDb.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}

void _createV6Schema(raw.Database db) {
  db.execute('''
    CREATE TABLE programs (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE workout_days (
      id TEXT NOT NULL PRIMARY KEY,
      program_id TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE program_workout_days (
      program_id TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
      workout_day_id TEXT NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      PRIMARY KEY (program_id, workout_day_id),
      UNIQUE (program_id, position)
    )
  ''');
  db.execute('''
    CREATE TABLE exercise_groups (
      id TEXT NOT NULL PRIMARY KEY,
      workout_day_id TEXT NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      kind_discriminator TEXT NOT NULL,
      kind_payload_json TEXT NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      UNIQUE (workout_day_id, position)
    )
  ''');
  db.execute('''
    CREATE TABLE exercises (
      id TEXT NOT NULL PRIMARY KEY,
      exercise_group_id TEXT NOT NULL REFERENCES exercise_groups(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      name TEXT NOT NULL,
      measurement_type_discriminator TEXT NOT NULL,
      measurement_type_payload_json TEXT NOT NULL,
      notes TEXT,
      video_url TEXT,
      planned_rest_seconds INTEGER,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      UNIQUE (exercise_group_id, position)
    )
  ''');
  db.execute('''
    CREATE TABLE sets (
      id TEXT NOT NULL PRIMARY KEY,
      exercise_id TEXT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      planned_values_discriminator TEXT NOT NULL,
      planned_values_payload_json TEXT NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      UNIQUE (exercise_id, position)
    )
  ''');
  db.execute('''
    CREATE TABLE sessions (
      id TEXT NOT NULL PRIMARY KEY,
      workout_day_id TEXT NOT NULL,
      snapshot_json TEXT NOT NULL,
      snapshot_hash TEXT NOT NULL,
      started_at_ms INTEGER NOT NULL,
      ended_at_ms INTEGER,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE session_exercises (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
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
  db.execute('''
    CREATE TABLE executed_sets (
      id TEXT NOT NULL PRIMARY KEY,
      session_exercise_id TEXT NOT NULL REFERENCES session_exercises(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      measurement_type_discriminator TEXT NOT NULL,
      actual_values_discriminator TEXT NOT NULL,
      actual_values_payload_json TEXT NOT NULL,
      planned_set_id_in_snapshot TEXT,
      completed_at_ms INTEGER NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      UNIQUE (session_exercise_id, position)
    )
  ''');
  db.execute('''
    CREATE TABLE session_notes (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      body TEXT NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL
    )
  ''');
  db.execute('''
    CREATE TABLE extra_work_items (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      body TEXT NOT NULL,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      UNIQUE (session_id, position)
    )
  ''');
}

void _seedRowInEveryTable(raw.Database db) {
  const progId = 'prog-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const wdId = 'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const egId = 'eg---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const exId = 'ex---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const setId = 'set--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const sessId = 'sess-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const sxId = 'sx---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const esId = 'es---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const noteId = 'note-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const extraId = 'ex2--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  db.execute('INSERT INTO programs VALUES (?, ?, ?, ?, ?)', [
    progId,
    'Old Program',
    _ts,
    _ts,
    4,
  ]);
  db.execute('INSERT INTO workout_days VALUES (?, ?, ?, ?, ?, ?)', [
    wdId,
    progId,
    'Day A',
    _ts,
    _ts,
    4,
  ]);
  db.execute('INSERT INTO program_workout_days VALUES (?, ?, ?)', [
    progId,
    wdId,
    0,
  ]);
  db.execute('INSERT INTO exercise_groups VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
    egId,
    wdId,
    0,
    'single',
    '{"type":"single"}',
    _ts,
    _ts,
    4,
  ]);
  db.execute(
    'INSERT INTO exercises VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      exId,
      egId,
      0,
      'Squat',
      'repBased',
      '{"type":"repBased"}',
      null,
      null,
      180,
      _ts,
      _ts,
      4,
    ],
  );
  // Pre-RepTarget JSON shape: `{"weightKg":...,"reps":...,"type":"repBased"}`.
  db.execute('INSERT INTO sets VALUES (?, ?, ?, ?, ?, ?, ?, ?)', [
    setId,
    exId,
    0,
    'repBased',
    '{"weightKg":80.0,"reps":8,"type":"repBased"}',
    _ts,
    _ts,
    4,
  ]);
  db.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    sessId,
    wdId,
    '{}',
    'deadbeef',
    _ts,
    null,
    _ts,
    _ts,
    4,
  ]);
  db.execute(
    'INSERT INTO session_exercises VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [sxId, sessId, 0, exId, 'unfinished', null, null, _ts, _ts, 4],
  );
  db.execute(
    'INSERT INTO executed_sets VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      esId,
      sxId,
      0,
      'repBased',
      'repBased',
      '{"weightKg":80.0,"reps":7,"type":"repBased"}',
      setId,
      _ts,
      _ts,
      _ts,
      4,
    ],
  );
  db.execute('INSERT INTO session_notes VALUES (?, ?, ?, ?, ?, ?)', [
    noteId,
    sessId,
    'felt heavy',
    _ts,
    _ts,
    4,
  ]);
  db.execute('INSERT INTO extra_work_items VALUES (?, ?, ?, ?, ?, ?, ?)', [
    extraId,
    sessId,
    0,
    '10 min walk',
    _ts,
    _ts,
    4,
  ]);
}
