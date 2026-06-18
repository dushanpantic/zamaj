import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart'
    hide WorkoutDay;
import 'package:zamaj/modules/persistence/mappers/session_mapper.dart';

const _ts = 1700000000000;
const _sessionId = 'sess-legacy--xxxxxxxxxxxxxxxxxxxxxxxxx';

void main() {
  test('v12→v13 migration adds is_deload defaulting to false for '
      'pre-existing sessions', () async {
    final file = File(
      '${Directory.systemTemp.path}/migration_isdeload_'
      '${DateTime.now().microsecondsSinceEpoch}.db',
    );
    try {
      // A real, hash-consistent snapshot so the row loads through the mapper.
      final day = WorkoutDay(
        id: 'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        programId: 'pg---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        name: 'Legacy day',
        exerciseGroups: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(_ts, isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(_ts, isUtc: true),
        schemaVersion: 8,
      );
      final snapshotJson = CanonicalJson.encode(day.toJson());
      final snapshotHash = CanonicalJson.sha256Hex(snapshotJson);

      final rawDb = raw.sqlite3.open(file.path);
      _createV12SessionsTable(rawDb);
      rawDb.execute('INSERT INTO sessions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [
        _sessionId,
        day.id,
        snapshotJson,
        snapshotHash,
        _ts,
        _ts + 3600000,
        _ts,
        _ts,
        8,
      ]);
      rawDb.execute('PRAGMA user_version = 12');
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      // Opening the database runs migrations.
      await db.customSelect('SELECT 1').get();

      // The column now exists and the legacy row defaults to false.
      final raw0 = await db
          .customSelect(
            'SELECT is_deload FROM sessions WHERE id = ?',
            variables: [const Variable<String>(_sessionId)],
          )
          .getSingle();
      expect(raw0.read<int>('is_deload'), 0);

      // And the read mapping surfaces it on the domain Session.
      final row = await (db.select(
        db.sessions,
      )..where((t) => t.id.equals(_sessionId))).getSingle();
      final session = SessionMapper().toDomain(row, [], [], [], []);
      expect(session.isDeload, isFalse);

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });
}

void _createV12SessionsTable(raw.Database db) {
  // v12 sessions table — unchanged since v5; no is_deload column yet.
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
}
