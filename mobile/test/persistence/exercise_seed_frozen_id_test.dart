import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/services/canonical_seed_catalog.dart';

/// Guards the append-only contract on seed ids: once an id ships it is
/// recorded in the lock file and must remain in the catalog forever. Changing
/// or removing a shipped id would orphan it in already-persisted session
/// snapshots, so the lock makes that a build-time failure rather than a
/// silent data drift.
void main() {
  test('every locked seed id is still present in the catalog', () {
    final catalogIds = CanonicalSeedCatalog.parse(
      File('assets/exercise_library_seed.json').readAsStringSync(),
    ).map((e) => e.id).toSet();

    final locked =
        (jsonDecode(
                  File(
                    'assets/exercise_library_seed.lock.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<String>();

    expect(locked, isNotEmpty, reason: 'the lock must record shipped ids');

    for (final id in locked) {
      expect(
        catalogIds,
        contains(id),
        reason:
            'locked id "$id" is missing from the catalog — seed ids are '
            'append-only; restore it instead of changing or removing it',
      );
    }
  });

  test('every catalog id is recorded in the lock', () {
    final catalogIds = CanonicalSeedCatalog.parse(
      File('assets/exercise_library_seed.json').readAsStringSync(),
    ).map((e) => e.id).toSet();

    final locked =
        (jsonDecode(
                  File(
                    'assets/exercise_library_seed.lock.json',
                  ).readAsStringSync(),
                )
                as List)
            .cast<String>()
            .toSet();

    for (final id in catalogIds) {
      expect(
        locked,
        contains(id),
        reason:
            'catalog id "$id" is not in the lock — run '
            'tool/assign_seed_uuids.dart to record it',
      );
    }
  });
}
