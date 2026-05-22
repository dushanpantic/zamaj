import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_exercise_library_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';

import '../support/generators.dart';

void main() {
  late AppDatabase db;
  late DriftProgramRepository programRepo;
  late DriftExerciseLibraryRepository libraryRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    programRepo = DriftProgramRepository(db: db);
    libraryRepo = DriftExerciseLibraryRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<domain.Exercise> makePlainExercise(Random rng, {String? name}) async {
    final program = await programRepo.createProgram(
      name: 'P${rng.nextInt(99)}',
    );
    final day = await programRepo.createWorkoutDay(
      programId: program.id,
      name: 'D',
    );
    final group = await programRepo.createExerciseGroup(
      workoutDayId: day.id,
      kind: const ExerciseGroupKind.single(),
      exercises: [
        domain.Exercise(
          id: anyUuidV4(rng),
          exerciseGroupId: '',
          position: 0,
          name: name ?? 'Bench Press',
          measurementType: const MeasurementType.repBased(),
          metadata: ExerciseMetadata.empty,
          sets: const [],
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          schemaVersion: 1,
        ),
      ],
    );
    return group.exercises.first;
  }

  group('Exercise.libraryExerciseId persistence', () {
    test(
      'round-trips a libraryExerciseId set on a template Exercise',
      () async {
        final rng = Random(1);
        final entry = await libraryRepo.create(
          name: 'BB Bench Press',
          measurementType: const MeasurementType.repBased(),
        );

        final exercise = await makePlainExercise(rng);
        expect(exercise.libraryExerciseId, isNull);

        await programRepo.updateExercise(
          exercise.copyWith(libraryExerciseId: entry.id),
        );

        final reloaded = await programRepo.getExercise(exercise.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.libraryExerciseId, equals(entry.id));
      },
    );

    test('unlink (set libraryExerciseId back to null) round-trips', () async {
      final rng = Random(2);
      final entry = await libraryRepo.create(
        name: 'OHP',
        measurementType: const MeasurementType.repBased(),
      );
      final exercise = await makePlainExercise(rng);

      await programRepo.updateExercise(
        exercise.copyWith(libraryExerciseId: entry.id),
      );
      final linked = await programRepo.getExercise(exercise.id);
      expect(linked!.libraryExerciseId, equals(entry.id));

      await programRepo.updateExercise(
        linked.copyWith(libraryExerciseId: null),
      );
      final unlinked = await programRepo.getExercise(exercise.id);
      expect(unlinked!.libraryExerciseId, isNull);
    });

    test('archiving the library entry does not break loading the linked '
        'template Exercise', () async {
      final rng = Random(3);
      final entry = await libraryRepo.create(
        name: 'BB Bench Press',
        measurementType: const MeasurementType.repBased(),
      );
      final exercise = await makePlainExercise(rng);
      await programRepo.updateExercise(
        exercise.copyWith(libraryExerciseId: entry.id),
      );

      await libraryRepo.archive(entry.id);

      final reloaded = await programRepo.getExercise(exercise.id);
      expect(reloaded, isNotNull);
      expect(
        reloaded!.libraryExerciseId,
        equals(entry.id),
        reason: 'archive is soft-delete; FK should still resolve',
      );

      final stillThere = await libraryRepo.get(entry.id);
      expect(stillThere, isNotNull);
      expect(stillThere!.archivedAt, isNotNull);
    });
  });
}
