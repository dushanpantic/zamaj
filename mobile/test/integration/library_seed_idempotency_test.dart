import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/canonical_seed_exercise.dart';
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_exercise_library_repository.dart';

import '../support/in_memory_app_database.dart';

void main() {
  late AppDatabase db;
  late DriftExerciseLibraryRepository repo;

  setUp(() {
    db = makeInMemoryDatabase();
    repo = DriftExerciseLibraryRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  final catalog = [
    CanonicalSeedExercise(
      id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      name: 'Barbell Bench Press',
      measurementType: const MeasurementType.repBased(),
      prominence: Prominence.common,
      primaryMuscles: const [MuscleGroup.chest],
      secondaryMuscles: const [MuscleGroup.triceps, MuscleGroup.shoulders],
    ),
    CanonicalSeedExercise(
      id: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      name: 'Overhead Press',
      measurementType: const MeasurementType.repBased(),
      prominence: Prominence.common,
      primaryMuscles: const [MuscleGroup.shoulders],
      secondaryMuscles: const [MuscleGroup.triceps],
    ),
  ];

  test(
    're-seeding creates no duplicates and preserves user edits to seeded rows',
    () async {
      await repo.seedCanonical(catalog);

      // The user renames a seeded entry and attaches a video URL.
      final seeded = await repo.get('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
      await repo.update(
        seeded!.copyWith(
          name: 'BB Bench',
          videoUrl: 'https://example.com/bb-bench',
        ),
      );

      // Re-seeding (a subsequent launch / app update).
      final reinserted = await repo.seedCanonical(catalog);

      expect(reinserted, equals(0), reason: 'no new rows on a second seed');
      final all = await repo.list();
      expect(all.length, equals(2), reason: 'no duplicate rows created');

      final edited = await repo.get('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
      expect(
        edited!.name,
        equals('BB Bench'),
        reason: 'rename survives reseed',
      );
      expect(
        edited.videoUrl,
        equals('https://example.com/bb-bench'),
        reason: 'video URL survives reseed',
      );
      expect(
        edited.source,
        equals(LibrarySource.canonicalSeed),
        reason: 'origin metadata is unchanged by the user edit',
      );
    },
  );
}
