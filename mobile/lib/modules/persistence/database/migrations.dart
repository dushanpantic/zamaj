import 'package:drift/drift.dart';
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
      // `superset_tag` was added to the schema in the session-flow-engine work
      // without bumping the version. Some dev databases were created via
      // `createAll` *after* that commit and already have the column; older
      // ones do not. Add it only if missing so both paths converge.
      if (!await _columnExists(db, 'session_exercises', 'superset_tag')) {
        await m.addColumn(db.sessionExercises, db.sessionExercises.supersetTag);
      }
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
}
