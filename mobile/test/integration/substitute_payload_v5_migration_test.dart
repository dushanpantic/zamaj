import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

const _plannedExerciseId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _sessionId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _sessionExerciseId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

String _seedSnapshotJson() {
  // Hand-rolled minimal snapshot in canonical JSON shape. Only the keys the
  // migration walks (`exerciseGroups[*].exercises[*]` with `id`, `sets[*]
  // .plannedValues`) need to be present.
  final snapshot = <String, dynamic>{
    'createdAt': '2024-01-01T00:00:00.000Z',
    'exerciseGroups': [
      {
        'createdAt': '2024-01-01T00:00:00.000Z',
        'exercises': [
          {
            'createdAt': '2024-01-01T00:00:00.000Z',
            'exerciseGroupId': 'g1',
            'id': _plannedExerciseId,
            'measurementType': {'type': 'repBased'},
            'metadata': {'notes': null, 'videoUrl': null},
            'name': 'Shoulder Press',
            'plannedRestSeconds': null,
            'position': 0,
            'schemaVersion': 1,
            'sets': [
              {
                'createdAt': '2024-01-01T00:00:00.000Z',
                'exerciseId': _plannedExerciseId,
                'id': 's1',
                'measurementType': {'type': 'repBased'},
                'plannedValues': {
                  'type': 'repBased',
                  'weightKg': 22.5,
                  'reps': 8,
                },
                'position': 0,
                'schemaVersion': 1,
                'updatedAt': '2024-01-01T00:00:00.000Z',
              },
              {
                'createdAt': '2024-01-01T00:00:00.000Z',
                'exerciseId': _plannedExerciseId,
                'id': 's2',
                'measurementType': {'type': 'repBased'},
                'plannedValues': {
                  'type': 'repBased',
                  'weightKg': 22.5,
                  'reps': 8,
                },
                'position': 1,
                'schemaVersion': 1,
                'updatedAt': '2024-01-01T00:00:00.000Z',
              },
              {
                'createdAt': '2024-01-01T00:00:00.000Z',
                'exerciseId': _plannedExerciseId,
                'id': 's3',
                'measurementType': {'type': 'repBased'},
                'plannedValues': {
                  'type': 'repBased',
                  'weightKg': 22.5,
                  'reps': 8,
                },
                'position': 2,
                'schemaVersion': 1,
                'updatedAt': '2024-01-01T00:00:00.000Z',
              },
            ],
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
        ],
        'id': 'g1',
        'kind': {'type': 'single'},
        'position': 0,
        'schemaVersion': 1,
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'workoutDayId': 'wd1',
      },
    ],
    'id': 'wd1',
    'name': 'Day 1',
    'programId': 'prog1',
    'schemaVersion': 1,
    'updatedAt': '2024-01-01T00:00:00.000Z',
  };
  return CanonicalJson.encode(snapshot);
}

void _seedV4Tables(raw.Database db, {required String substitutePayloadJson}) {
  // Sessions / session_exercises rebuilt at v4 shape (post-superset_tag).
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

  final snapshotJson = _seedSnapshotJson();
  final hash = CanonicalJson.sha256Hex(snapshotJson);

  db.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?, NULL, ?, ?, ?)', [
    _sessionId,
    'wd1',
    snapshotJson,
    hash,
    1700000000000,
    1700000000000,
    1700000000000,
    2,
  ]);

  db.execute(
    'INSERT INTO session_exercises '
    'VALUES (?, ?, ?, ?, ?, ?, NULL, ?, ?, ?)',
    [
      _sessionExerciseId,
      _sessionId,
      1024,
      _plannedExerciseId,
      'replaced',
      substitutePayloadJson,
      1700000000000,
      1700000000000,
      2,
    ],
  );
  db.execute('PRAGMA user_version = 4');
}

void main() {
  test('v4→v5 migration backfills plannedValues and setCount on legacy '
      'substitute payloads', () async {
    final file = File(
      '${Directory.systemTemp.path}/substitute_v5_migration_'
      '${DateTime.now().microsecondsSinceEpoch}.db',
    );
    try {
      final rawDb = raw.sqlite3.open(file.path);
      final legacyPayload = CanonicalJson.encode(<String, dynamic>{
        'name': 'Nordic Shoulder',
        'measurementType': {'type': 'timeBased'},
        'metadata': null,
      });
      _seedV4Tables(rawDb, substitutePayloadJson: legacyPayload);
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();

      final rows = await db
          .customSelect(
            'SELECT substitute_payload_json, schema_version '
            'FROM session_exercises WHERE id = ?',
            variables: [const Variable<String>(_sessionExerciseId)],
          )
          .get();
      expect(rows, hasLength(1));
      final upgradedJson = rows.single.read<String>('substitute_payload_json');
      final upgraded = jsonDecode(upgradedJson) as Map<String, dynamic>;

      expect(upgraded['name'], 'Nordic Shoulder');
      expect(upgraded['measurementType'], {'type': 'timeBased'});
      expect(upgraded['setCount'], 3);
      expect(upgraded['plannedValues'], {
        'type': 'repBased',
        'weightKg': 22.5,
        'reps': 8,
      });
      expect(rows.single.read<int>('schema_version'), SchemaVersions.domain);

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });

  test(
    'v4→v5 migration is idempotent on rows already at v3 payload shape',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/substitute_v5_migration_idempotent_'
        '${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final rawDb = raw.sqlite3.open(file.path);
        final v3Payload = CanonicalJson.encode(<String, dynamic>{
          'name': 'Cable Fly',
          'measurementType': {'type': 'repBased'},
          'metadata': null,
          'plannedValues': {'type': 'repBased', 'weightKg': 10.0, 'reps': 12},
          'setCount': 4,
        });
        _seedV4Tables(rawDb, substitutePayloadJson: v3Payload);
        rawDb.close();

        final db = AppDatabase(NativeDatabase(file));
        await db.customSelect('SELECT 1').get();

        final rows = await db
            .customSelect(
              'SELECT substitute_payload_json FROM session_exercises '
              'WHERE id = ?',
              variables: [const Variable<String>(_sessionExerciseId)],
            )
            .get();
        final upgraded =
            jsonDecode(rows.single.read<String>('substitute_payload_json'))
                as Map<String, dynamic>;
        expect(upgraded['setCount'], 4);
        expect(upgraded['plannedValues'], {
          'type': 'repBased',
          'weightKg': 10.0,
          'reps': 12,
        });
        expect(upgraded['name'], 'Cable Fly');

        await db.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}
