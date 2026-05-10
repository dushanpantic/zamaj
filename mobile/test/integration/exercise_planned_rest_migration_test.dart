import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as raw;
import 'package:zamaj/modules/persistence/database/app_database.dart';

const _ts = 1700000000000;
const _progId = 'prog-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _wdId = 'wd---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _egId = 'eg---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
const _exId = 'ex---xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

void main() {
  test(
    'v1→v2 migration preserves exercise rows and sets planned_rest_seconds to NULL',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/exercise_planned_rest_migration_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final rawDb = raw.sqlite3.open(file.path);
        rawDb.execute('''
          CREATE TABLE programs (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            schema_version INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          CREATE TABLE workout_days (
            id TEXT NOT NULL PRIMARY KEY,
            program_id TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            schema_version INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          CREATE TABLE exercise_groups (
            id TEXT NOT NULL PRIMARY KEY,
            workout_day_id TEXT NOT NULL REFERENCES workout_days(id) ON DELETE CASCADE,
            position INTEGER NOT NULL,
            kind_discriminator TEXT NOT NULL,
            kind_payload_json TEXT NOT NULL,
            created_at_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            schema_version INTEGER NOT NULL
          )
        ''');
        rawDb.execute('''
          CREATE TABLE exercises (
            id TEXT NOT NULL PRIMARY KEY,
            exercise_group_id TEXT NOT NULL REFERENCES exercise_groups(id) ON DELETE CASCADE,
            position INTEGER NOT NULL,
            name TEXT NOT NULL,
            measurement_type_discriminator TEXT NOT NULL,
            measurement_type_payload_json TEXT NOT NULL,
            notes TEXT,
            video_url TEXT,
            created_at_ms INTEGER NOT NULL,
            updated_at_ms INTEGER NOT NULL,
            schema_version INTEGER NOT NULL
          )
        ''');
        rawDb.execute('PRAGMA user_version = 1');

        rawDb.execute('INSERT INTO programs VALUES (?, ?, ?, ?, ?)', [
          _progId,
          'Test Program',
          _ts,
          _ts,
          1,
        ]);
        rawDb.execute('INSERT INTO workout_days VALUES (?, ?, ?, ?, ?, ?)', [
          _wdId,
          _progId,
          'Day A',
          _ts,
          _ts,
          1,
        ]);
        rawDb.execute(
          'INSERT INTO exercise_groups VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [_egId, _wdId, 0, 'single', '{}', _ts, _ts, 1],
        );
        rawDb.execute(
          'INSERT INTO exercises VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [_exId, _egId, 0, 'Squat', 'repBased', '{}', null, null, _ts, _ts, 1],
        );

        rawDb.close();

        final migratedDb = AppDatabase(NativeDatabase(file));
        await migratedDb.customSelect('SELECT 1').get();

        final rows = await migratedDb.select(migratedDb.exercises).get();

        expect(rows.length, 1);

        final row = rows.first;
        expect(row.id, _exId);
        expect(row.exerciseGroupId, _egId);
        expect(row.position, 0);
        expect(row.name, 'Squat');
        expect(row.measurementTypeDiscriminator, 'repBased');
        expect(row.measurementTypePayloadJson, '{}');
        expect(row.notes, isNull);
        expect(row.videoUrl, isNull);
        expect(row.createdAtMs, _ts);
        expect(row.updatedAtMs, _ts);
        expect(row.schemaVersion, 1);
        expect(row.plannedRestSeconds, isNull);

        await migratedDb.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}
