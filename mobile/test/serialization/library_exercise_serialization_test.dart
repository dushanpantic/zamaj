import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/library_exercise.dart';
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1);

  LibraryExercise seeded() => LibraryExercise(
    id: '11111111-1111-4111-8111-111111111111',
    name: 'Barbell Bench Press',
    measurementType: const MeasurementType.repBased(),
    prominence: Prominence.common,
    primaryMuscles: const [MuscleGroup.chest],
    secondaryMuscles: const [MuscleGroup.triceps, MuscleGroup.shoulders],
    source: LibrarySource.canonicalSeed,
    videoUrl: 'https://example.com/bench',
    cues: 'Retract scapula.',
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );

  group('LibraryExercise JSON round-trip with new fields', () {
    test('round-trips prominence, muscles, and source', () {
      final entry = seeded();
      final restored = LibraryExercise.fromJson(entry.toJson());
      expect(restored, equals(entry));
      expect(restored.prominence, Prominence.common);
      expect(restored.source, LibrarySource.canonicalSeed);
      expect(restored.primaryMuscles, const [MuscleGroup.chest]);
      expect(
        restored.secondaryMuscles,
        const [MuscleGroup.triceps, MuscleGroup.shoulders],
      );
    });

    test('serializes enums as their bare names', () {
      final json = seeded().toJson();
      expect(json['prominence'], 'common');
      expect(json['source'], 'canonicalSeed');
      expect(json['primaryMuscles'], ['chest']);
      expect(json['secondaryMuscles'], ['triceps', 'shoulders']);
    });

    test('round-trips a specialized entry with empty secondary muscles', () {
      final entry = LibraryExercise(
        id: '22222222-2222-4222-8222-222222222222',
        name: 'Plank',
        measurementType: const MeasurementType.timeBased(),
        prominence: Prominence.specialized,
        primaryMuscles: const [MuscleGroup.abs],
        source: LibrarySource.canonicalSeed,
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
      final restored = LibraryExercise.fromJson(entry.toJson());
      expect(restored, equals(entry));
      expect(restored.secondaryMuscles, isEmpty);
    });
  });
}
