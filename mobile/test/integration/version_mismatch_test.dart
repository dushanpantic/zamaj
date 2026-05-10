import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

void main() {
  test(
    'reopening a DB whose user_version > SchemaVersions.drift throws VersionMismatchError',
    () async {
      final file = File(
        '${Directory.systemTemp.path}/version_mismatch_test_${DateTime.now().microsecondsSinceEpoch}.db',
      );
      try {
        final initialDb = AppDatabase(NativeDatabase(file));
        await initialDb.customSelect('SELECT 1').get();
        await initialDb.close();

        final rawDb = AppDatabase(NativeDatabase(file));
        await rawDb.customStatement(
          'PRAGMA user_version = ${SchemaVersions.drift + 1}',
        );
        await rawDb.close();

        final reopenedDb = AppDatabase(NativeDatabase(file));
        await expectLater(
          reopenedDb.customSelect('SELECT 1').get(),
          throwsA(
            isA<VersionMismatchError>()
                .having(
                  (e) => e.persisted,
                  'persisted',
                  SchemaVersions.drift + 1,
                )
                .having((e) => e.expected, 'expected', SchemaVersions.drift),
          ),
        );
        await reopenedDb.close();
      } finally {
        if (file.existsSync()) file.deleteSync();
      }
    },
  );
}
