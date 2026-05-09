import 'package:drift/drift.dart';

class AppMigrations {
  static Future<void> onUpgrade(Migrator m, int from, int to) async {
    // TODO(migrations): add `if (from < N) { ... }` branches here as schema evolves
  }
}
