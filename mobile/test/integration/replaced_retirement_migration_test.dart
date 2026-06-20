import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

import '../support/generators.dart';

const _ts = 1700000000000;

const _sessionId = 'sess-legacy--xxxxxxxxxxxxxxxxxxxxxxxxx';
const _originalId = 'sx-original--xxxxxxxxxxxxxxxxxxxxxxxxx';
const _plannedId = 'planned-orig-xxxxxxxxxxxxxxxxxxxxxxxxx';

void main() {
  test('v14→v15 migrates a legacy replaced row to a skipped original plus an '
      'added exercise carrying the former substitute plan', () async {
    final file = _tempDbFile('replaced_retirement_migration');
    // Identical JSON shape to the legacy SubstituteExercise payload.
    final plan = anyAddedExercisePlan(Random(7), libraryLinked: true);
    final payloadJson = CanonicalJson.encode(plan.toJson());

    try {
      final rawDb = raw.sqlite3.open(file.path);
      _createV14Schema(rawDb);
      _seedSession(rawDb);
      _seedSessionExercise(
        rawDb,
        id: _originalId,
        position: 0,
        stateDiscriminator: 'replaced',
        substitutePayloadJson: payloadJson,
      );
      rawDb.execute('PRAGMA user_version = 14');
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      // Opening the database runs migrations up to SchemaVersions.drift.
      await db.customSelect('SELECT 1').get();

      final rows = await _sessionExerciseRows(db, _sessionId);

      // The original is terminated as skipped and no longer carries a
      // substitute payload.
      final original = rows.firstWhere((r) => r['id'] == _originalId);
      expect(original['state_discriminator'], 'skipped');
      expect(original['substitute_payload_json'], isNull);
      expect(original['added_plan_json'], isNull);

      // A new added-exercise row carries the former payload as its inline plan.
      final added = rows.singleWhere((r) => r['id'] != _originalId);
      expect(added['state_discriminator'], 'unfinished');
      expect(added['substitute_payload_json'], isNull);
      expect((added['position']! as int) > 0, isTrue);

      final addedPlan = AddedExercisePlan.fromJson(
        jsonDecode(added['added_plan_json']! as String) as Map<String, dynamic>,
      );
      expect(addedPlan.name, plan.name);
      expect(addedPlan.setCount, plan.setCount);
      expect(addedPlan.libraryExerciseId, plan.libraryExerciseId);

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });

  test('a DB with no replaced rows upgrades to v15 as a clean no-op', () async {
    final file = _tempDbFile('replaced_retirement_noop');
    try {
      final rawDb = raw.sqlite3.open(file.path);
      _createV14Schema(rawDb);
      _seedSession(rawDb);
      _seedSessionExercise(
        rawDb,
        id: _originalId,
        position: 0,
        stateDiscriminator: 'unfinished',
        substitutePayloadJson: null,
      );
      rawDb.execute('PRAGMA user_version = 14');
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();

      final rows = await _sessionExerciseRows(db, _sessionId);
      expect(rows, hasLength(1));
      expect(rows.single['id'], _originalId);
      expect(rows.single['state_discriminator'], 'unfinished');

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });
}

File _tempDbFile(String label) => File(
  '${Directory.systemTemp.path}/${label}_'
  '${DateTime.now().microsecondsSinceEpoch}.db',
);

Future<List<Map<String, Object?>>> _sessionExerciseRows(
  AppDatabase db,
  String sessionId,
) async {
  final rows = await db
      .customSelect(
        'SELECT id, position, state_discriminator, substitute_payload_json, '
        'added_plan_json FROM session_exercises WHERE session_id = ? '
        'ORDER BY position',
        variables: [Variable<String>(sessionId)],
      )
      .get();
  return rows
      .map(
        (r) => {
          'id': r.read<String>('id'),
          'position': r.read<int>('position'),
          'state_discriminator': r.read<String>('state_discriminator'),
          'substitute_payload_json': r.read<String?>(
            'substitute_payload_json',
          ),
          'added_plan_json': r.read<String?>('added_plan_json'),
        },
      )
      .toList();
}

void _seedSession(raw.Database db) {
  db.execute(
    'INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      _sessionId,
      'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
      '{"exerciseGroups":[]}',
      'a' * 64,
      _ts,
      null,
      _ts,
      _ts,
      10,
      0,
    ],
  );
}

void _seedSessionExercise(
  raw.Database db, {
  required String id,
  required int position,
  required String stateDiscriminator,
  required String? substitutePayloadJson,
}) {
  db.execute(
    'INSERT INTO session_exercises VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      _sessionId,
      position,
      _plannedId,
      stateDiscriminator,
      substitutePayloadJson,
      null,
      null,
      _ts,
      _ts,
      10,
    ],
  );
}

void _createV14Schema(raw.Database db) {
  // v14 sessions: gained is_deload at v13.
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
      schema_version INTEGER NOT NULL,
      is_deload INTEGER NOT NULL DEFAULT 0
    )
  ''');
  // v14 session_exercises: gained added_plan_json at v14, still carries the
  // legacy substitute_payload_json column.
  db.execute('''
    CREATE TABLE session_exercises (
      id TEXT NOT NULL PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      planned_exercise_id_in_snapshot TEXT NOT NULL,
      state_discriminator TEXT NOT NULL,
      substitute_payload_json TEXT,
      added_plan_json TEXT,
      superset_tag TEXT,
      created_at_ms INTEGER NOT NULL,
      updated_at_ms INTEGER NOT NULL,
      schema_version INTEGER NOT NULL,
      UNIQUE (session_id, position)
    )
  ''');
}
