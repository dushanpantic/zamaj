import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_exercise_library_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';

import '../support/generators.dart';
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

  group('create', () {
    test('persists a new entry with required fields only', () async {
      final entry = await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );

      expect(entry.id.length, equals(36));
      expect(entry.name, equals('BB Bench Press'));
      expect(entry.measurementType, isA<RepBasedMeasurement>());
      expect(entry.videoUrl, isNull);
      expect(entry.cues, isNull);
      expect(entry.archivedAt, isNull);
      expect(entry.schemaVersion, equals(SchemaVersions.domain));
      expect(entry.createdAt.isUtc, isTrue);
      expect(entry.updatedAt.isUtc, isTrue);
    });

    test('persists a new entry with optional fields populated', () async {
      final entry = await repo.create(
        name: 'Plank',
        measurementType: const MeasurementType.timeBased(),
        videoUrl: 'https://example.com/plank',
        cues: 'Tight glutes. Neutral spine.',
      );
      expect(entry.videoUrl, equals('https://example.com/plank'));
      expect(entry.cues, equals('Tight glutes. Neutral spine.'));
      expect(entry.measurementType, isA<TimeBasedMeasurement>());
    });
  });

  group('get', () {
    test('returns null for an unknown id', () async {
      final result = await repo.get('00000000-0000-4000-8000-000000000000');
      expect(result, isNull);
    });

    test('returns the persisted entry', () async {
      final created = await repo.create(
        name: 'Pull Up',
        measurementType: const MeasurementType.bodyweight(),
      );
      final fetched = await repo.get(created.id);
      expect(fetched, equals(created));
    });
  });

  group('list', () {
    test('returns active entries sorted by nameLower', () async {
      await repo.create(
        name: 'Zercher Squat',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.create(
        name: 'Cable Fly',
        measurementType: const MeasurementType.repBased(),
      );

      final entries = await repo.list();
      expect(entries.map((e) => e.name).toList(), [
        'BB Bench Press',
        'Cable Fly',
        'Zercher Squat',
      ]);
    });

    test('excludes archived entries by default', () async {
      final keep = await repo.create(
        name: 'Active',
        measurementType: const MeasurementType.repBased(),
      );
      final drop = await repo.create(
        name: 'Going Away',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.archive(drop.id);

      final entries = await repo.list();
      expect(entries.map((e) => e.id), [keep.id]);
    });

    test('includes archived entries when requested', () async {
      final keep = await repo.create(
        name: 'Active',
        measurementType: const MeasurementType.repBased(),
      );
      final archived = await repo.create(
        name: 'Going Away',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.archive(archived.id);

      final entries = await repo.list(includeArchived: true);
      expect(entries.map((e) => e.id).toSet(), {keep.id, archived.id});
    });

    test('filters by measurementType', () async {
      final rep = await repo.create(
        name: 'Rep Move',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.create(
        name: 'Time Move',
        measurementType: const MeasurementType.timeBased(),
      );

      final entries = await repo.list(
        measurementType: const MeasurementType.repBased(),
      );
      expect(entries.map((e) => e.id), [rep.id]);
    });

    test('filters by nameQuery (case insensitive substring)', () async {
      final bench = await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.create(
        name: 'Cable Fly',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.create(
        name: 'OHP',
        measurementType: const MeasurementType.repBased(),
      );

      final entries = await repo.list(nameQuery: 'bEnCh');
      expect(entries.map((e) => e.id), [bench.id]);
    });

    test('whitespace-only nameQuery is treated as no filter', () async {
      await repo.create(
        name: 'A',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.create(
        name: 'B',
        measurementType: const MeasurementType.repBased(),
      );
      final entries = await repo.list(nameQuery: '   ');
      expect(entries.length, equals(2));
    });
  });

  group('update', () {
    test('updates mutable fields and bumps updatedAt', () async {
      final created = await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );

      final edited = created.copyWith(
        name: 'Barbell Bench Press',
        videoUrl: 'https://example.com/bench',
        cues: 'Tight upper back.',
      );
      final updated = await repo.update(edited);

      expect(updated.name, equals('Barbell Bench Press'));
      expect(updated.videoUrl, equals('https://example.com/bench'));
      expect(updated.cues, equals('Tight upper back.'));
      expect(
        updated.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(created.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('refreshes nameLower so subsequent queries find the new name',
        () async {
      final created = await repo.create(
        name: 'Old Name',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.update(created.copyWith(name: 'Different Name'));

      final byOld = await repo.findByNormalizedName('Old Name');
      expect(byOld, isNull);
      final byNew = await repo.findByNormalizedName('different NAME');
      expect(byNew?.id, equals(created.id));
    });

    test('throws NotFoundError for an unknown id', () async {
      final phantom = anyLibraryExercise(Random(0)).copyWith(
        id: '00000000-0000-4000-8000-000000000000',
      );
      expect(
        () => repo.update(phantom),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  group('archive / unarchive', () {
    test('archive stamps archivedAt; unarchive clears it', () async {
      final created = await repo.create(
        name: 'X',
        measurementType: const MeasurementType.repBased(),
      );
      final archived = await repo.archive(created.id);
      expect(archived.archivedAt, isNotNull);
      expect(archived.archivedAt!.isUtc, isTrue);

      final restored = await repo.unarchive(created.id);
      expect(restored.archivedAt, isNull);
    });

    test('archive throws NotFoundError for an unknown id', () async {
      expect(
        () => repo.archive('00000000-0000-4000-8000-000000000000'),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('unarchive throws NotFoundError for an unknown id', () async {
      expect(
        () => repo.unarchive('00000000-0000-4000-8000-000000000000'),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  group('findByNormalizedName', () {
    test('matches regardless of case and surrounding whitespace', () async {
      final created = await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );

      for (final query in [
        'bb bench press',
        'BB BENCH PRESS',
        '  bb bench press  ',
        '\tBB Bench Press\n',
      ]) {
        final hit = await repo.findByNormalizedName(query);
        expect(hit?.id, equals(created.id), reason: 'query="$query"');
      }
    });

    test('finds archived entries too', () async {
      final created = await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );
      await repo.archive(created.id);
      final hit = await repo.findByNormalizedName('BB Bench Press');
      expect(hit?.id, equals(created.id));
      expect(hit?.archivedAt, isNotNull);
    });

    test('returns null when there is no match', () async {
      await repo.create(
        name: 'Pull Up',
        measurementType: const MeasurementType.repBased(),
      );
      final hit = await repo.findByNormalizedName('Squat');
      expect(hit, isNull);
    });
  });

  group('onDelete setNull cascade for referencing Exercise rows', () {
    test('hard-deleting a library entry nulls the libraryExerciseId on '
        'every Exercise that referenced it', () async {
      final programRepo = DriftProgramRepository(db: db);

      final entry = await repo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );

      final program = await programRepo.createProgram(name: 'PPL');
      final day = await programRepo.createWorkoutDay(
        programId: program.id,
        name: 'Push',
      );
      final group = await programRepo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          domain.Exercise(
            id: anyUuidV4(Random(7)),
            exerciseGroupId: '',
            position: 0,
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: const [],
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            schemaVersion: 1,
          ),
        ],
      );

      // Link the exercise to the library entry.
      final exercise = group.exercises.first;
      await programRepo.updateExercise(
        exercise.copyWith(libraryExerciseId: entry.id),
      );

      final linked = await programRepo.getExercise(exercise.id);
      expect(linked!.libraryExerciseId, equals(entry.id));

      // Hard-delete the library row directly (no API on the repo).
      await (db.delete(
        db.libraryExercises,
      )..where((t) => t.id.equals(entry.id))).go();

      final orphaned = await programRepo.getExercise(exercise.id);
      expect(orphaned!.libraryExerciseId, isNull,
          reason: 'onDelete: setNull should null the FK, not cascade');
    });
  });
}
