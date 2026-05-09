import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('foreign_keys pragma is enabled after database open', () async {
    final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(result.read<int>('foreign_keys'), 1);
  });
}
