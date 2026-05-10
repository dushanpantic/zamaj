import 'package:drift/drift.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

class AppMigrations {
  static Future<void> onUpgrade(Migrator m, int from, int to) async {
    final db = m.database as AppDatabase;
    if (from < 2) {
      await m.addColumn(db.exercises, db.exercises.plannedRestSeconds);
    }
  }
}
