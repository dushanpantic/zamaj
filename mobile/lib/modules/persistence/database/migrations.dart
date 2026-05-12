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
  }
}
