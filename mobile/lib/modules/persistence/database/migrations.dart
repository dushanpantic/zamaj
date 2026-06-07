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
    if (from < 6) {
      await _denseExecutedSetPositions(db);
    }
    if (from < 7) {
      // Rep-target rollout: rewrite of planned_set JSON shape. Existing data
      // dropped — single-install app, no compat layer.
      await _wipeAllDomainTables(db);
    }
    if (from < 8) {
      await _renormalizeSessionExercisePositions(db);
    }
    if (from < 9) {
      await m.addColumn(db.exerciseGroups, db.exerciseGroups.roleDiscriminator);
    }
    if (from < 10) {
      // Split from v9 because v9 shipped without this backfill; the broken
      // app still stamped the DB as v9, so the snapshot rewrite must live
      // in its own version to re-fire on the next open.
      await _backfillSessionSnapshotRole(db);
    }
    if (from < 11) {
      await m.createTable(db.libraryExercises);
      await m.createIndex(db.libraryExercisesNameLower);
      await m.addColumn(db.exercises, db.exercises.libraryExerciseId);
    }
    if (from < 12) {
      await _clearLibraryForCanonicalReseed(m, db);
    }
  }

  /// Clears the manually-built exercise library so the embedded canonical
  /// catalog can seed from a clean slate. Adds the seed metadata columns
  /// (`source`, `prominence`, `primary_muscles_json`, `secondary_muscles_json`),
  /// unlinks every program exercise, then drops every library row.
  ///
  /// One-time and intentional — single-install app, no compat layer, matching
  /// the v6→v7 [_wipeAllDomainTables] precedent. After this, the user re-links
  /// program exercises via the existing picker ("Keep local" preserves names).
  ///
  /// The `library_exercise_id` null-out is explicit because drift disables
  /// foreign-key enforcement during migrations, so the `ON DELETE SET NULL`
  /// cascade does not fire — without this the delete would orphan the FK.
  ///
  /// The columns are added behind an existence guard: an upgrade originating
  /// before v11 runs the `from < 11` `createTable` first, which builds the
  /// table from the current (v12) schema and therefore already includes these
  /// columns — re-adding them would raise "duplicate column name".
  static Future<void> _clearLibraryForCanonicalReseed(
    Migrator m,
    AppDatabase db,
  ) async {
    const table = 'library_exercises';
    if (!await _columnExists(db, table, 'source')) {
      await m.addColumn(db.libraryExercises, db.libraryExercises.source);
    }
    if (!await _columnExists(db, table, 'prominence')) {
      await m.addColumn(db.libraryExercises, db.libraryExercises.prominence);
    }
    if (!await _columnExists(db, table, 'primary_muscles_json')) {
      await m.addColumn(
        db.libraryExercises,
        db.libraryExercises.primaryMusclesJson,
      );
    }
    if (!await _columnExists(db, table, 'secondary_muscles_json')) {
      await m.addColumn(
        db.libraryExercises,
        db.libraryExercises.secondaryMusclesJson,
      );
    }
    await db.customStatement('UPDATE exercises SET library_exercise_id = NULL');
    await db.customStatement('DELETE FROM library_exercises');
  }

  /// Rewrites every session's canonical snapshot JSON to include the new
  /// `role` field on each `ExerciseGroup`, defaulted to `"main"`. Without
  /// this, deserializing a pre-v9 snapshot would default role on the domain
  /// side, then [SessionSnapshot]'s invariant rejects the row because the
  /// stored canonical bytes no longer round-trip.
  ///
  /// Idempotent: groups that already carry a `role` key are left alone.
  static Future<void> _backfillSessionSnapshotRole(AppDatabase db) async {
    if (!await _tableExists(db, 'sessions')) return;

    final sessions = await db
        .customSelect('SELECT id, snapshot_json FROM sessions')
        .get();

    for (final session in sessions) {
      final sessionId = session.read<String>('id');
      final snapshot =
          jsonDecode(session.read<String>('snapshot_json'))
              as Map<String, dynamic>;

      final groups = snapshot['exerciseGroups'] as List<dynamic>?;
      if (groups == null) continue;
      var changed = false;
      for (final group in groups) {
        final g = group as Map<String, dynamic>;
        if (!g.containsKey('role')) {
          g['role'] = 'main';
          changed = true;
        }
      }
      if (!changed) continue;

      final canonical = CanonicalJson.encode(snapshot);
      final hash = CanonicalJson.sha256Hex(canonical);
      await db.customStatement(
        'UPDATE sessions SET snapshot_json = ?, snapshot_hash = ?, '
        'schema_version = ? WHERE id = ?',
        [canonical, hash, SchemaVersions.domain, sessionId],
      );
    }
  }

  /// Re-anchors `session_exercises.position` to template order for every
  /// in-flight session by walking the captured snapshot. The pre-v8 repo
  /// pushed terminal exercises past unfinished ones to make the (now-removed)
  /// global cursor advance; this restores a stable order matching the
  /// snapshot so cards in the overview and rows in the export reflect the
  /// planned layout verbatim. `position = snapshotIndex * 1024`, where
  /// `snapshotIndex` walks `snapshot.exerciseGroups[].exercises[]` in order.
  static Future<void> _renormalizeSessionExercisePositions(
    AppDatabase db,
  ) async {
    if (!await _tableExists(db, 'sessions')) return;
    if (!await _tableExists(db, 'session_exercises')) return;

    final sessions = await db
        .customSelect(
          'SELECT id, snapshot_json FROM sessions WHERE ended_at_ms IS NULL',
        )
        .get();

    for (final session in sessions) {
      final sessionId = session.read<String>('id');
      final snapshot =
          jsonDecode(session.read<String>('snapshot_json'))
              as Map<String, dynamic>;

      final order = _walkSnapshotPlannedExerciseIds(snapshot);
      if (order.isEmpty) continue;
      final indexByPlannedId = <String, int>{
        for (var i = 0; i < order.length; i++) order[i]: i,
      };

      final rows = await db
          .customSelect(
            'SELECT id, planned_exercise_id_in_snapshot '
            'FROM session_exercises WHERE session_id = ?',
            variables: [Variable<String>(sessionId)],
          )
          .get();

      // Park current positions in a disjoint negative range to dodge the
      // (session_id, position) UNIQUE constraint while we rewrite.
      await db.customStatement(
        'UPDATE session_exercises SET position = -1 - position '
        'WHERE session_id = ?',
        [sessionId],
      );

      for (final row in rows) {
        final id = row.read<String>('id');
        final plannedId = row.read<String>('planned_exercise_id_in_snapshot');
        final index = indexByPlannedId[plannedId];
        if (index == null) {
          throw ValidationError(
            entityId: id,
            invariant: 'session_exercise_resolvable_in_snapshot',
            message:
                'Cannot resolve plannedExerciseIdInSnapshot=$plannedId in '
                'session=$sessionId snapshot during v8 migration',
          );
        }
        await db.customStatement(
          'UPDATE session_exercises SET position = ? WHERE id = ?',
          [index * 1024, id],
        );
      }
    }
  }

  static List<String> _walkSnapshotPlannedExerciseIds(
    Map<String, dynamic> snapshot,
  ) {
    final result = <String>[];
    final groups = snapshot['exerciseGroups'] as List<dynamic>?;
    if (groups == null) return result;
    for (final group in groups) {
      final exercises =
          (group as Map<String, dynamic>)['exercises'] as List<dynamic>?;
      if (exercises == null) continue;
      for (final exercise in exercises) {
        final ex = exercise as Map<String, dynamic>;
        result.add(ex['id'] as String);
      }
    }
    return result;
  }

  /// Deletes every row from the domain-data tables. Used by the v6→v7
  /// destructive migration to drop programs and session history whose
  /// `planned_values_payload_json` / snapshot blobs use the pre-RepTarget
  /// wire format.
  ///
  /// Order matters when foreign keys are enforced: delete the leaves first,
  /// then their parents.
  static Future<void> _wipeAllDomainTables(AppDatabase db) async {
    const tables = [
      'executed_sets',
      'session_notes',
      'extra_work_items',
      'session_exercises',
      'sessions',
      'sets',
      'exercises',
      'exercise_groups',
      'workout_days',
      'program_workout_days',
      'programs',
    ];
    for (final table in tables) {
      if (await _tableExists(db, table)) {
        await db.customStatement('DELETE FROM $table');
      }
    }
  }

  /// Rewrites `executed_sets.position` from the legacy LexoRank-style values
  /// (1024, 2048, ...) to dense chronological indices (0, 1, 2, ...) within
  /// each `session_exercise_id`, preserving the existing relative order.
  /// ExecutedSets are append-only — they never reorder — so the gap-based
  /// scheme it inherited from the template side was overkill and caused
  /// confusion with [WorkoutSet.position].
  static Future<void> _denseExecutedSetPositions(AppDatabase db) async {
    if (!await _tableExists(db, 'executed_sets')) return;
    await db.customStatement(
      'UPDATE executed_sets '
      'SET position = ('
      '  SELECT COUNT(*) FROM executed_sets AS others '
      '  WHERE others.session_exercise_id = executed_sets.session_exercise_id '
      '  AND others.position < executed_sets.position'
      ')',
    );
  }

  static Future<bool> _tableExists(AppDatabase db, String table) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
          variables: [Variable<String>(table)],
        )
        .get();
    return rows.isNotEmpty;
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
