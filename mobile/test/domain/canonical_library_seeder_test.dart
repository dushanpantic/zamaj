import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/canonical_seed_exercise.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/repositories/exercise_library_repository.dart';
import 'package:zamaj/modules/domain/services/canonical_library_seeder.dart';

/// Captures what the seeder forwards without touching a database.
class _RecordingLibraryRepository implements ExerciseLibraryRepository {
  int seedCalls = 0;
  List<CanonicalSeedExercise>? seededEntries;

  @override
  Future<int> seedCanonical(List<CanonicalSeedExercise> entries) async {
    seedCalls++;
    seededEntries = entries;
    return entries.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _validCatalogJson = jsonEncode([
  {
    'id': '11111111-1111-4111-8111-111111111111',
    'name': 'Bench',
    'measurementType': 'repBased',
    'prominence': 'common',
    'primaryMuscles': ['chest'],
    'secondaryMuscles': ['triceps'],
  },
  {
    'id': '22222222-2222-4222-8222-222222222222',
    'name': 'Squat',
    'measurementType': 'repBased',
    'prominence': 'specialized',
    'primaryMuscles': ['quadriceps'],
    'secondaryMuscles': ['glutes'],
  },
]);

void main() {
  group('CanonicalLibrarySeeder', () {
    test('parses the catalog and forwards every entry to the repo', () async {
      final repo = _RecordingLibraryRepository();
      final seeder = CanonicalLibrarySeeder(repo);

      final inserted = await seeder.seed(_validCatalogJson);

      expect(inserted, equals(2));
      expect(repo.seedCalls, equals(1));
      expect(
        repo.seededEntries?.map((e) => e.name).toList(),
        equals(['Bench', 'Squat']),
      );
      expect(
        repo.seededEntries?.map((e) => e.measurementType).toList(),
        everyElement(isA<MeasurementType>()),
      );
    });

    test('surfaces a typed error for a malformed catalog and never '
        'silently swallows it', () async {
      final repo = _RecordingLibraryRepository();
      final seeder = CanonicalLibrarySeeder(repo);

      await expectLater(
        () => seeder.seed('{"not": "an array"}'),
        throwsA(isA<DeserializationError>()),
      );
      expect(
        repo.seedCalls,
        equals(0),
        reason: 'a bad catalog must not reach the repository',
      );
    });
  });
}
