import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/library_exercise.dart';
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';

import '../support/generators.dart';

void main() {
  final rng = Random(11);

  LibraryExercise makeEntry({
    String? id,
    String name = 'BB Bench Press',
    MeasurementType measurementType = const MeasurementType.repBased(),
    Prominence prominence = Prominence.common,
    List<MuscleGroup> primaryMuscles = const [],
    List<MuscleGroup> secondaryMuscles = const [],
    LibrarySource source = LibrarySource.user,
    String? videoUrl,
    String? cues,
    DateTime? archivedAt,
  }) {
    final now = DateTime.utc(2026, 1, 1);
    return LibraryExercise(
      id: id ?? anyUuidV4(rng),
      name: name,
      measurementType: measurementType,
      prominence: prominence,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      source: source,
      videoUrl: videoUrl,
      cues: cues,
      archivedAt: archivedAt,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
  }

  group('LibraryExercise construction invariants', () {
    test('accepts a minimal valid entry', () {
      final entry = makeEntry();
      expect(entry.name, 'BB Bench Press');
      expect(entry.archivedAt, isNull);
      expect(entry.videoUrl, isNull);
      expect(entry.cues, isNull);
    });

    test('accepts an entry with all optional fields populated', () {
      final entry = makeEntry(
        videoUrl: 'https://example.com/bench',
        cues: 'Retract scapula. Drive through heels.',
        archivedAt: DateTime.utc(2026, 2, 1),
      );
      expect(entry.videoUrl, 'https://example.com/bench');
      expect(entry.cues, isNotEmpty);
      expect(entry.archivedAt, isNotNull);
    });

    test('id with non-36-char length throws ValidationError', () {
      expect(
        () => makeEntry(id: 'too-short'),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'id_not_uuid_v4',
          ),
        ),
      );
    });

    test('untrimmed name throws ValidationError', () {
      expect(
        () => makeEntry(name: '  Bench Press  '),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'name_not_trimmed_or_empty',
          ),
        ),
      );
    });

    test('leading-whitespace name throws ValidationError', () {
      expect(() => makeEntry(name: ' Bench'), throwsA(isA<ValidationError>()));
    });

    test('trailing-whitespace name throws ValidationError', () {
      expect(() => makeEntry(name: 'Bench '), throwsA(isA<ValidationError>()));
    });

    test('empty name throws ValidationError', () {
      expect(
        () => makeEntry(name: ''),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'name_not_trimmed_or_empty',
          ),
        ),
      );
    });

    test('empty videoUrl throws ValidationError', () {
      expect(
        () => makeEntry(videoUrl: ''),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'video_url_empty',
          ),
        ),
      );
    });

    test('empty cues throws ValidationError', () {
      expect(
        () => makeEntry(cues: ''),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'cues_empty',
          ),
        ),
      );
    });

    test('archivedAt is permitted in the past, present and future', () {
      final past = makeEntry(archivedAt: DateTime.utc(2020));
      final future = makeEntry(archivedAt: DateTime.utc(2099));
      expect(past.archivedAt, isNotNull);
      expect(future.archivedAt, isNotNull);
    });
  });

  group('LibraryExercise prominence, muscles, and source', () {
    test('defaults to common prominence, user source, empty muscles', () {
      final entry = LibraryExercise(
        id: anyUuidV4(rng),
        name: 'Plain Entry',
        measurementType: const MeasurementType.repBased(),
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        schemaVersion: 1,
      );
      expect(entry.prominence, Prominence.common);
      expect(entry.source, LibrarySource.user);
      expect(entry.primaryMuscles, isEmpty);
      expect(entry.secondaryMuscles, isEmpty);
    });

    test('accepts explicit prominence, muscles, and source', () {
      final entry = makeEntry(
        prominence: Prominence.specialized,
        primaryMuscles: const [MuscleGroup.chest],
        secondaryMuscles: const [MuscleGroup.triceps, MuscleGroup.shoulders],
        source: LibrarySource.canonicalSeed,
      );
      expect(entry.prominence, Prominence.specialized);
      expect(entry.primaryMuscles, const [MuscleGroup.chest]);
      expect(
        entry.secondaryMuscles,
        const [MuscleGroup.triceps, MuscleGroup.shoulders],
      );
      expect(entry.source, LibrarySource.canonicalSeed);
    });

    test('disjoint primary/secondary muscle sets are accepted', () {
      final entry = makeEntry(
        primaryMuscles: const [MuscleGroup.lats, MuscleGroup.upperBack],
        secondaryMuscles: const [MuscleGroup.biceps],
      );
      expect(entry.primaryMuscles, isNotEmpty);
      expect(entry.secondaryMuscles, isNotEmpty);
    });

    test('overlapping primary/secondary muscles throw ValidationError', () {
      expect(
        () => makeEntry(
          primaryMuscles: const [MuscleGroup.chest, MuscleGroup.triceps],
          secondaryMuscles: const [MuscleGroup.triceps],
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'muscles_not_disjoint',
          ),
        ),
      );
    });
  });

  group('LibraryExercise JSON round-trip', () {
    test('round-trips with all fields populated', () {
      final entry = makeEntry(
        videoUrl: 'https://example.com/v',
        cues: 'Cue text',
        archivedAt: DateTime.utc(2026, 3, 1),
      );
      final json = entry.toJson();
      final restored = LibraryExercise.fromJson(json);
      expect(restored, equals(entry));
    });

    test('round-trips with nulls preserved', () {
      final entry = makeEntry();
      final restored = LibraryExercise.fromJson(entry.toJson());
      expect(restored.videoUrl, isNull);
      expect(restored.cues, isNull);
      expect(restored.archivedAt, isNull);
    });

    test('generator produces 36-char ids and trimmed non-empty names', () {
      final rng2 = Random(12);
      for (var i = 0; i < 100; i++) {
        final entry = anyLibraryExercise(rng2);
        expect(entry.id.length, equals(36));
        expect(entry.name.isNotEmpty, isTrue);
        expect(entry.name, equals(entry.name.trim()));
      }
    });
  });
}
