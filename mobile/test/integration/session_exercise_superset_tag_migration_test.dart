import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/persistence/database/app_database.dart';

void main() {
  test(
    'v3→v4 migration adds session_exercises.superset_tag when missing',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/superset_tag_migration_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final rawDb = raw.sqlite3.open(file.path);
        // Seed a v3 DB that mirrors the pre-`superset_tag` shape: session_exercises
        // lacks the column because it was added to the Dart schema without a
        // migration. Only the tables touched by this regression are recreated.
        rawDb.execute('''
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
        rawDb.execute('''
          CREATE TABLE session_exercises (
            id TEXT NOT NULL PRIMARY KEY,
            session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
            position INTEGER NOT NULL,
            planned_exercise_id_in_snapshot TEXT NOT NULL,
            state_discriminator TEXT NOT NULL,
            substitute_payload_json TEXT,
            created_at_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            schema_version INTEGER NOT NULL,
            UNIQUE (session_id, position)
          )
        ''');
        rawDb.execute('PRAGMA user_version = 3');
        rawDb.close();

        final db = AppDatabase(NativeDatabase(file));
        // Force migration to run by issuing any query.
        await db.customSelect('SELECT 1').get();

        final info = await db
            .customSelect("PRAGMA table_info('session_exercises')")
            .get();
        final names = info.map((r) => r.read<String>('name')).toList();
        expect(names, contains('superset_tag'));

        await db.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );

  test('v3→v4 migration is a noop when superset_tag already exists', () async {
    final file = File(
      '${Directory.systemTemp.path}/superset_tag_migration_idempotent_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    try {
      final rawDb = raw.sqlite3.open(file.path);
      rawDb.execute('''
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
      rawDb.execute('''
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
      rawDb.execute('PRAGMA user_version = 3');
      rawDb.close();

      final db = AppDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();

      final info = await db
          .customSelect("PRAGMA table_info('session_exercises')")
          .get();
      final supersetTag = info
          .where((r) => r.read<String>('name') == 'superset_tag')
          .toList();
      expect(supersetTag, hasLength(1));

      await db.close();
    } finally {
      if (file.existsSync()) file.deleteSync();
    }
  });
}
