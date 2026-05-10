import 'package:drift/native.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

AppDatabase makeInMemoryDatabase() => AppDatabase(NativeDatabase.memory());

class InMemoryDatabaseHelper {
  late AppDatabase db;

  Future<void> setUp() async {
    db = makeInMemoryDatabase();
  }

  Future<void> tearDown() async {
    await db.close();
  }
}
