import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

abstract final class AppMigrations {
  static Future<void> onUpgrade(Migrator m, int from, int to) async {
    final db = m.database as AppDatabase;
    if (from < 2) {
      await m.addColumn(db.exercises, db.exercises.plannedRestSeconds);
    }
    if (from < 3) {
      await m.createIndex(db.workoutDaysProgramId);
      await m.createIndex(db.sessionsWorkoutDayId);
      await m.createIndex(db.sessionExercisesSessionState);
      await m.createIndex(db.sessionNotesSessionId);
    }
    if (from < 4) {
      if (!await _columnExists(db, 'session_exercises', 'superset_tag')) {
        await m.addColumn(db.sessionExercises, db.sessionExercises.supersetTag);
      }
    }
    if (from < 5) {
      await _upgradeSubstitutePayloadsToV3(db);
    }
  }

  static Future<bool> _columnExists(
    AppDatabase db,
    String table,
    String column,
  ) async {
    final rows = await db.customSelect("PRAGMA table_info('$table')").get();
    return rows.any((r) => r.read<String>('name') == column);
  }

  /// Rewrites every `replaced` session-exercise row's `substitute_payload_json`
  /// into the v3 shape: adds `plannedValues` and `setCount`, backfilled from
  /// the originating planned exercise in the session's immutable snapshot.
  ///
  /// Idempotent: rows whose payload already contains `plannedValues` are left
  /// alone. Raises a [ValidationError] when a row's
  /// `plannedExerciseIdInSnapshot` cannot be resolved in the snapshot, rather
  /// than silently writing zero values.
  static Future<void> _upgradeSubstitutePayloadsToV3(AppDatabase db) async {
    final replacedRows = await db
        .customSelect(
          'SELECT id, session_id, planned_exercise_id_in_snapshot, '
          'substitute_payload_json '
          'FROM session_exercises '
          "WHERE state_discriminator = 'replaced' "
          'AND substitute_payload_json IS NOT NULL',
        )
        .get();

    final snapshotCache = <String, Map<String, dynamic>>{};

    for (final row in replacedRows) {
      final exerciseId = row.read<String>('id');
      final sessionId = row.read<String>('session_id');
      final plannedExerciseId = row.read<String>(
        'planned_exercise_id_in_snapshot',
      );
      final payloadJson = row.read<String>('substitute_payload_json');
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      if (payload.containsKey('plannedValues') &&
          payload.containsKey('setCount')) {
        continue;
      }

      final snapshot = await _loadSnapshot(db, sessionId, snapshotCache);

      final plannedExercise = _findExerciseInSnapshot(
        snapshot,
        plannedExerciseId,
      );
      if (plannedExercise == null) {
        throw ValidationError(
          entityId: exerciseId,
          invariant: 'replaced_snapshot_exercise_resolvable',
          message:
              'Cannot resolve plannedExerciseIdInSnapshot=$plannedExerciseId '
              'in session=$sessionId during v5 migration',
        );
      }

      final sets = plannedExercise['sets'] as List<dynamic>;
      if (sets.isEmpty) {
        throw ValidationError(
          entityId: exerciseId,
          invariant: 'replaced_snapshot_has_sets',
          message:
              'Planned exercise $plannedExerciseId in session $sessionId has '
              'no sets; cannot backfill v3 substitute payload',
        );
      }
      final firstSet = sets.first as Map<String, dynamic>;
      final plannedValues = firstSet['plannedValues'] as Map<String, dynamic>;

      final upgraded = <String, dynamic>{
        ...payload,
        'plannedValues': plannedValues,
        'setCount': sets.length,
      };
      final upgradedJson = CanonicalJson.encode(upgraded);

      await db.customStatement(
        'UPDATE session_exercises '
        'SET substitute_payload_json = ?, schema_version = ? '
        'WHERE id = ?',
        [upgradedJson, SchemaVersions.domain, exerciseId],
      );
    }
  }

  static Future<Map<String, dynamic>> _loadSnapshot(
    AppDatabase db,
    String sessionId,
    Map<String, Map<String, dynamic>> cache,
  ) async {
    final cached = cache[sessionId];
    if (cached != null) return cached;
    final rows = await db
        .customSelect(
          'SELECT snapshot_json FROM sessions WHERE id = ?',
          variables: [Variable<String>(sessionId)],
        )
        .get();
    if (rows.isEmpty) {
      throw ValidationError(
        entityId: sessionId,
        invariant: 'session_row_exists',
        message:
            'Cannot locate session $sessionId while migrating substitute '
            'payloads to v3',
      );
    }
    final snapshot =
        jsonDecode(rows.single.read<String>('snapshot_json'))
            as Map<String, dynamic>;
    cache[sessionId] = snapshot;
    return snapshot;
  }

  static Map<String, dynamic>? _findExerciseInSnapshot(
    Map<String, dynamic> snapshot,
    String plannedExerciseId,
  ) {
    final groups = snapshot['exerciseGroups'] as List<dynamic>?;
    if (groups == null) return null;
    for (final group in groups) {
      final exercises =
          (group as Map<String, dynamic>)['exercises'] as List<dynamic>?;
      if (exercises == null) continue;
      for (final exercise in exercises) {
        final ex = exercise as Map<String, dynamic>;
        if (ex['id'] == plannedExerciseId) return ex;
      }
    }
    return null;
  }
}
