import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/persistence/database/app_database.dart';

const _ts = 1700000000000;

void main() {
  test(
    'v10→v11 migration creates library_exercises table and adds '
    'library_exercise_id FK on exercises, leaving existing rows with NULL',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/library_migration_test_'
        '${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final rawDb = raw.sqlite3.open(file.path);
        _createV10Schema(rawDb);
        _seedExercise(rawDb);
        rawDb.execute('PRAGMA user_version = 10');
        rawDb.close();

        final migratedDb = AppDatabase(NativeDatabase(file));
        // Touching the database opens it and runs migrations.
        await migratedDb.customSelect('SELECT 1').get();

        // The new table exists.
        final tableInfo = await migratedDb
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
              variables: [const Variable<String>('library_exercises')],
            )
            .get();
        expect(tableInfo, isNotEmpty,
            reason: 'library_exercises table should be created');

        // The new column exists on exercises and is nullable.
        final exerciseCols =
            await migratedDb.customSelect("PRAGMA table_info('exercises')").get();
        final libCol = exerciseCols.firstWhere(
          (r) => r.read<String>('name') == 'library_exercise_id',
          orElse: () => throw StateError(
              'library_exercise_id column should exist on exercises'),
        );
        expect(libCol.read<int>('notnull'), equals(0),
            reason: 'library_exercise_id must be nullable');

        // The covering index on library_exercises.name_lower exists.
        final indexInfo = await migratedDb
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='index' AND name = ?",
              variables: [
                const Variable<String>('library_exercises_name_lower'),
              ],
            )
            .get();
        expect(indexInfo, isNotEmpty,
            reason: 'library_exercises_name_lower index should be created');

        // Existing exercise row survived the migration and has NULL FK.
        final exerciseRows = await migratedDb
            .customSelect(
              'SELECT id, library_exercise_id FROM exercises',
            )
            .get();
        expect(exerciseRows.length, equals(1));
        expect(
          exerciseRows.single.readNullable<String>('library_exercise_id'),
          isNull,
          reason: 'existing rows should carry library_exercise_id = NULL',
        );

        // No library_exercises rows yet.
        final libRows = await migratedDb
            .customSelect('SELECT COUNT(*) AS c FROM library_exercises')
            .get();
        expect(libRows.single.read<int>('c'), equals(0));

        await migratedDb.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}

void _createV10Schema(raw.Database db) {
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
      role_discriminator TEXT NOT NULL DEFAULT 'main',
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

void _seedExercise(raw.Database db) {
  const progId = 'prog-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const wdId = 'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const egId = 'eg---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  const exId = 'ex---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  db.execute('INSERT INTO programs VALUES (?, ?, ?, ?, ?)', [
    progId,
    'Old Program',
    _ts,
    _ts,
    7,
  ]);
  db.execute('INSERT INTO workout_days VALUES (?, ?, ?, ?, ?, ?)', [
    wdId,
    progId,
    'Day A',
    _ts,
    _ts,
    7,
  ]);
  db.execute('INSERT INTO program_workout_days VALUES (?, ?, ?)', [
    progId,
    wdId,
    0,
  ]);
  db.execute(
    'INSERT INTO exercise_groups VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      egId,
      wdId,
      0,
      'single',
      '{"type":"single"}',
      'main',
      _ts,
      _ts,
      7,
    ],
  );
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
      7,
    ],
  );
}
