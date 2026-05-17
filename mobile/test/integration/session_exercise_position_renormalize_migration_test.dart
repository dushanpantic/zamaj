import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/persistence/database/app_database.dart';

const _ts = 1700000000000;
const _gap = 1024;

const _sessionInFlight = 'sess-flight--xxxxxxxxxxxxxxxxxxxxxxxxx';
const _sessionDone = 'sess-done----xxxxxxxxxxxxxxxxxxxxxxxxx';

// Planned-exercise ids embedded in each session's snapshot. The snapshot order
// (group, then exercise within group) determines the canonical post-migration
// position layout.
const _plannedExA = 'planned-ex-A-xxxxxxxxxxxxxxxxxxxxxxxxx';
const _plannedExB = 'planned-ex-B-xxxxxxxxxxxxxxxxxxxxxxxxx';
const _plannedExC = 'planned-ex-C-xxxxxxxxxxxxxxxxxxxxxxxxx';

const _sxA = 'sx-A---------xxxxxxxxxxxxxxxxxxxxxxxxx';
const _sxB = 'sx-B---------xxxxxxxxxxxxxxxxxxxxxxxxx';
const _sxC = 'sx-C---------xxxxxxxxxxxxxxxxxxxxxxxxx';
const _sxDoneA = 'sxd-A--------xxxxxxxxxxxxxxxxxxxxxxxxx';
const _sxDoneB = 'sxd-B--------xxxxxxxxxxxxxxxxxxxxxxxxx';

void main() {
  test('v7→v8 migration renormalizes session_exercises.position from snapshot '
      'for in-flight sessions and leaves completed sessions alone', () async {
    final file = File(
      '${Directory.systemTemp.path}/session_exercise_position_renormalize_'
      '${DateTime.now().microsecondsSinceEpoch}.db',
    );
    try {
      final rawDb = raw.sqlite3.open(file.path);
      _createV7Schema(rawDb);
      _seedV7Rows(rawDb);
      rawDb.execute('PRAGMA user_version = 7');
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      // Opening the database runs migrations.
      await db.customSelect('SELECT 1').get();

      Future<List<Map<String, Object?>>> sxRows(String sessionId) async {
        final rows = await db
            .customSelect(
              'SELECT id, position FROM session_exercises '
              'WHERE session_id = ? ORDER BY position',
              variables: [Variable<String>(sessionId)],
            )
            .get();
        return rows
            .map(
              (r) => {
                'id': r.read<String>('id'),
                'position': r.read<int>('position'),
              },
            )
            .toList();
      }

      // In-flight session: positions were reanchored past lock pre-v8
      // (A=2*_gap, B=0, C=1*_gap). After migration, snapshot order [A,B,C]
      // gets canonical positions 0, _gap, 2*_gap.
      final inFlight = await sxRows(_sessionInFlight);
      expect(inFlight, [
        {'id': _sxA, 'position': 0},
        {'id': _sxB, 'position': _gap},
        {'id': _sxC, 'position': 2 * _gap},
      ]);

      // Completed session: ended_at_ms is set, so migration must NOT touch
      // it. Original (intentionally weird) positions remain.
      final done = await sxRows(_sessionDone);
      expect(done, [
        {'id': _sxDoneB, 'position': 7},
        {'id': _sxDoneA, 'position': 42},
      ]);

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });
}

void _seedV7Rows(raw.Database db) {
  // Minimal snapshot JSON: only the bits the migration walks
  // (exerciseGroups[].exercises[].id).
  const inFlightSnapshot =
      '{"exerciseGroups":['
      '{"exercises":[{"id":"$_plannedExA"},{"id":"$_plannedExB"}]},'
      '{"exercises":[{"id":"$_plannedExC"}]}'
      ']}';
  const doneSnapshot =
      '{"exerciseGroups":['
      '{"exercises":[{"id":"$_plannedExA"},{"id":"$_plannedExB"}]}'
      ']}';

  db.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    _sessionInFlight,
    'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    inFlightSnapshot,
    'a' * 64,
    _ts,
    null,
    _ts,
    _ts,
    5,
  ]);
  db.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
    _sessionDone,
    'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    doneSnapshot,
    'b' * 64,
    _ts,
    _ts + 3600000,
    _ts,
    _ts,
    5,
  ]);

  // In-flight session: positions shuffled by prior reanchoring. Snapshot
  // order is [A, B, C], stored order here is [B@0, C@1024, A@2048].
  void insertSx(String id, String sessionId, int position, String plannedId) {
    db.execute(
      'INSERT INTO session_exercises VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        id,
        sessionId,
        position,
        plannedId,
        'unfinished',
        null,
        null,
        _ts,
        _ts,
        5,
      ],
    );
  }

  insertSx(_sxB, _sessionInFlight, 0, _plannedExB);
  insertSx(_sxC, _sessionInFlight, 1 * _gap, _plannedExC);
  insertSx(_sxA, _sessionInFlight, 2 * _gap, _plannedExA);

  // Completed session: arbitrary positions (7, 42) that don't match the
  // _gap-aligned scheme. Migration must leave them untouched because
  // ended_at_ms is non-null.
  insertSx(_sxDoneA, _sessionDone, 42, _plannedExA);
  insertSx(_sxDoneB, _sessionDone, 7, _plannedExB);
}

void _createV7Schema(raw.Database db) {
  // v7 schema is identical to v6 — the v6→v7 migration only wiped rows.
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
