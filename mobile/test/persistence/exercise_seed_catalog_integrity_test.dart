import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/canonical_seed_exercise.dart';
import 'package:zamaj/modules/domain/services/canonical_seed_catalog.dart';

/// Canonical RFC 4122 v4: version nibble `4`, variant nibble in `8..b`.
final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late List<CanonicalSeedExercise> catalog;

  setUpAll(() {
    // Parsing also validates every enum (measurementType, prominence,
    // MuscleGroup) and the per-entry value invariants; a bad value here
    // throws and fails the whole suite.
    final json = File('assets/exercise_library_seed.json').readAsStringSync();
    catalog = CanonicalSeedCatalog.parse(json);
  });

  test('the catalog holds a substantial number of movements', () {
    expect(catalog, isNotEmpty);
    expect(
      catalog.length,
      greaterThanOrEqualTo(60),
      reason: 'the authored catalog should ship ~60-80 movements',
    );
  });

  test('every id is a canonical UUIDv4', () {
    for (final e in catalog) {
      expect(
        _uuidV4.hasMatch(e.id),
        isTrue,
        reason: '"${e.name}" has a non-v4 id: "${e.id}"',
      );
    }
  });

  test('ids are unique across the catalog', () {
    final ids = catalog.map((e) => e.id).toList();
    expect(ids.toSet().length, equals(ids.length));
  });

  test('every name is trimmed and non-empty', () {
    for (final e in catalog) {
      expect(e.name, equals(e.name.trim()), reason: 'untrimmed: "${e.name}"');
      expect(e.name, isNotEmpty);
    }
  });

  test('every entry declares at least one primary muscle', () {
    for (final e in catalog) {
      expect(
        e.primaryMuscles,
        isNotEmpty,
        reason: '"${e.name}" has no primary muscles',
      );
    }
  });

  test('primary and secondary muscles are disjoint', () {
    for (final e in catalog) {
      final overlap = e.primaryMuscles.toSet().intersection(
        e.secondaryMuscles.toSet(),
      );
      expect(
        overlap,
        isEmpty,
        reason: '"${e.name}" lists ${overlap.map((m) => m.name)} in both',
      );
    }
  });
}
