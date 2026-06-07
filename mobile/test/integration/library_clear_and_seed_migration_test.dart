import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/persistence/database/app_database.dart';

const _ts = 1700000000000;

const _progId = 'prog-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _wdId = 'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _egId = 'eg---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _exId = 'ex---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _libId = 'lib--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _sessId = 'sess-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

void main() {
  test(
    'v11→v12 migration wipes library, nulls FK, leaves programs/sessions intact',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/library_clear_and_seed_migration_test_'
        '${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final rawDb = raw.sqlite3.open(file.path);
        _createV11Schema(rawDb);
        _seed(rawDb);
        rawDb.execute('PRAGMA user_version = 11');
        rawDb.close();

        final db = AppDatabase(NativeDatabase(file));
        // Touching the database opens it and runs migrations.
        await db.customSelect('SELECT 1').get();

        // The four new seed columns exist on library_exercises.
        final libCols = await db
            .customSelect("PRAGMA table_info('library_exercises')")
            .get();
        final libColNames = libCols
            .map((r) => r.read<String>('name'))
            .toSet();
        for (final col in const [
          'source',
          'prominence',
          'primary_muscles_json',
          'secondary_muscles_json',
        ]) {
          expect(
            libColNames,
            contains(col),
            reason: '$col column should be added in v12',
          );
        }

        Future<int> count(String table) async {
          final rows = await db
              .customSelect('SELECT COUNT(*) AS c FROM $table')
              .get();
          return rows.single.read<int>('c');
        }

        // The old manual library entries are gone.
        expect(
          await count('library_exercises'),
          equals(0),
          reason: 'all LibraryExercises rows must be cleared',
        );

        // The program and its exercise survive, name unchanged, FK nulled.
        final exerciseRows = await db
            .customSelect(
              'SELECT name, library_exercise_id FROM exercises WHERE id = ?',
              variables: [const Variable<String>(_exId)],
            )
            .get();
        expect(exerciseRows, hasLength(1));
        expect(exerciseRows.single.read<String>('name'), equals('BB Bench'));
        expect(
          exerciseRows.single.readNullable<String>('library_exercise_id'),
          isNull,
          reason: 'program exercise must be unlinked after the wipe',
        );

        // Program row intact.
        final programRows = await db
            .customSelect(
              'SELECT name FROM programs WHERE id = ?',
              variables: [const Variable<String>(_progId)],
            )
            .get();
        expect(programRows, hasLength(1));
        expect(programRows.single.read<String>('name'), equals('Old Program'));

        // Session history intact.
        expect(await count('sessions'), equals(1));

        await db.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}

void _seed(raw.Database db) {
  db.execute('INSERT INTO programs VALUES (?, ?, ?, ?, ?)', [
    _progId,
    'Old Program',
    _ts,
    _ts,
    8,
  ]);
  db.execute('INSERT INTO workout_days VALUES (?, ?, ?, ?, ?, ?)', [
    _wdId,
    _progId,
    'Day A',
    _ts,
    _ts,
    8,
  ]);
  db.execute('INSERT INTO program_workout_days VALUES (?, ?, ?)', [
    _progId,
    _wdId,
    0,
  ]);
  db.execute('INSERT INTO exercise_groups VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    _egId,
    _wdId,
    0,
    'single',
    '{"type":"single"}',
    'main',
    _ts,
    _ts,
    8,
  ]);
  // A manually-created library entry...
  db.execute(
    'INSERT INTO library_exercises '
    '(id, name, name_lower, measurement_type_discriminator, '
    'measurement_type_payload_json, video_url, cues, archived_at_ms, '
    'created_at_ms, updated_at_ms, schema_version) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      _libId,
      'My Bench',
      'my bench',
      'repBased',
      '{"type":"repBased"}',
      null,
      null,
      null,
      _ts,
      _ts,
      8,
    ],
  );
  // ...and a program exercise linked to it, with a user-chosen local name.
  db.execute(
    'INSERT INTO exercises '
    '(id, exercise_group_id, position, name, measurement_type_discriminator, '
    'measurement_type_payload_json, notes, video_url, planned_rest_seconds, '
    'library_exercise_id, created_at_ms, updated_at_ms, schema_version) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      _exId,
      _egId,
      0,
      'BB Bench',
      'repBased',
      '{"type":"repBased"}',
      null,
      null,
      180,
      _libId,
      _ts,
      _ts,
      8,
    ],
  );
  db.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    _sessId,
    _wdId,
    '{}',
    'deadbeef',
    _ts,
    null,
    _ts,
    _ts,
    8,
  ]);
}

void _createV11Schema(raw.Database db) {
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
    CREATE TABLE library_exercises (
      id TEXT NOT NULL PRIMARY KEY,
      name TEXT NOT NULL,
      name_lower TEXT NOT NULL,
      measurement_type_discriminator TEXT NOT NULL,
      measurement_type_payload_json TEXT NOT NULL,
      video_url TEXT,
      cues TEXT,
      archived_at_ms INTEGER,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL
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
      library_exercise_id TEXT REFERENCES library_exercises(id) ON DELETE SET NULL,
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
