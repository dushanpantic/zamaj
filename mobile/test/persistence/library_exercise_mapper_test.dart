import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/library_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/mappers/library_exercise_mapper.dart';

void main() {
  final mapper = LibraryExerciseMapper();

  const id = '11111111-1111-4111-8111-111111111111';

  const seededRow = LibraryExercise(
    id: id,
    name: 'Barbell Bench Press',
    nameLower: 'barbell bench press',
    measurementTypeDiscriminator: 'repBased',
    measurementTypePayloadJson: '{"type":"repBased"}',
    source: 'canonicalSeed',
    prominence: 'common',
    primaryMusclesJson: '["chest"]',
    secondaryMusclesJson: '["triceps","shoulders"]',
    videoUrl: null,
    cues: null,
    archivedAtMs: null,
    createdAtMs: 1700000000000,
    updatedAtMs: 1700000001000,
    schemaVersion: 8,
  );

  group('LibraryExerciseMapper new fields', () {
    test('toDomain decodes source, prominence, and muscle lists', () {
      final entry = mapper.toDomain(seededRow);
      expect(entry.source, LibrarySource.canonicalSeed);
      expect(entry.prominence, Prominence.common);
      expect(entry.primaryMuscles, const [MuscleGroup.chest]);
      expect(entry.secondaryMuscles, const [
        MuscleGroup.triceps,
        MuscleGroup.shoulders,
      ]);
    });

    test('toRow encodes source, prominence, and muscle lists as JSON', () {
      final entry = domain.LibraryExercise(
        id: id,
        name: 'Barbell Bench Press',
        measurementType: const MeasurementType.repBased(),
        prominence: Prominence.specialized,
        primaryMuscles: const [MuscleGroup.lats],
        secondaryMuscles: const [MuscleGroup.biceps],
        source: LibrarySource.canonicalSeed,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          1700000000000,
          isUtc: true,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          1700000001000,
          isUtc: true,
        ),
        schemaVersion: 8,
      );

      final companion = mapper.toRow(entry);

      expect(companion.source.value, 'canonicalSeed');
      expect(companion.prominence.value, 'specialized');
      expect(companion.primaryMusclesJson.value, '["lats"]');
      expect(companion.secondaryMusclesJson.value, '["biceps"]');
    });

    test('round-trips a domain entry through toRow then toDomain', () {
      final entry = domain.LibraryExercise(
        id: id,
        name: 'Plank',
        measurementType: const MeasurementType.timeBased(),
        prominence: Prominence.specialized,
        primaryMuscles: const [MuscleGroup.abs],
        secondaryMuscles: const [],
        source: LibrarySource.user,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          1700000000000,
          isUtc: true,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          1700000001000,
          isUtc: true,
        ),
        schemaVersion: 8,
      );

      final companion = mapper.toRow(entry);
      final row = LibraryExercise(
        id: companion.id.value,
        name: companion.name.value,
        nameLower: companion.nameLower.value,
        measurementTypeDiscriminator:
            companion.measurementTypeDiscriminator.value,
        measurementTypePayloadJson: companion.measurementTypePayloadJson.value,
        source: companion.source.value,
        prominence: companion.prominence.value,
        primaryMusclesJson: companion.primaryMusclesJson.value,
        secondaryMusclesJson: companion.secondaryMusclesJson.value,
        videoUrl: companion.videoUrl.value,
        cues: companion.cues.value,
        archivedAtMs: companion.archivedAtMs.value,
        createdAtMs: companion.createdAtMs.value,
        updatedAtMs: companion.updatedAtMs.value,
        schemaVersion: companion.schemaVersion.value,
      );

      expect(mapper.toDomain(row), equals(entry));
    });
  });
}
