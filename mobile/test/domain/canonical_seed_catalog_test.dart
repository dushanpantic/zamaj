import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';
import 'package:zamaj/modules/domain/services/canonical_seed_catalog.dart';

void main() {
  Map<String, dynamic> benchEntry({
    String id = '11111111-1111-4111-8111-111111111111',
    String name = 'Barbell Bench Press',
    String measurementType = 'repBased',
    String prominence = 'common',
    List<String> primaryMuscles = const ['chest'],
    List<String> secondaryMuscles = const ['triceps', 'shoulders'],
    String? videoUrl,
    String? cues,
  }) => {
    'id': id,
    'name': name,
    'measurementType': measurementType,
    'prominence': prominence,
    'primaryMuscles': primaryMuscles,
    'secondaryMuscles': secondaryMuscles,
    'videoUrl': ?videoUrl,
    'cues': ?cues,
  };

  String catalog(List<Map<String, dynamic>> entries) => jsonEncode(entries);

  group('CanonicalSeedCatalog.parse — happy path', () {
    test('parses a well-formed catalog into seed exercises', () {
      final json = catalog([
        benchEntry(),
        benchEntry(
          id: '22222222-2222-4222-8222-222222222222',
          name: 'Plank',
          measurementType: 'timeBased',
          prominence: 'specialized',
          primaryMuscles: const ['abs'],
          secondaryMuscles: const [],
        ),
      ]);

      final entries = CanonicalSeedCatalog.parse(json);

      expect(entries, hasLength(2));
      final bench = entries.first;
      expect(bench.id, '11111111-1111-4111-8111-111111111111');
      expect(bench.name, 'Barbell Bench Press');
      expect(bench.measurementType, const MeasurementType.repBased());
      expect(bench.prominence, Prominence.common);
      expect(bench.primaryMuscles, const [MuscleGroup.chest]);
      expect(
        bench.secondaryMuscles,
        const [MuscleGroup.triceps, MuscleGroup.shoulders],
      );

      final plank = entries.last;
      expect(plank.measurementType, const MeasurementType.timeBased());
      expect(plank.prominence, Prominence.specialized);
      expect(plank.secondaryMuscles, isEmpty);
    });

    test('parses optional videoUrl and cues', () {
      final json = catalog([
        benchEntry(videoUrl: 'https://example.com/v', cues: 'Brace.'),
      ]);
      final entry = CanonicalSeedCatalog.parse(json).single;
      expect(entry.videoUrl, 'https://example.com/v');
      expect(entry.cues, 'Brace.');
    });

    test('omitted secondaryMuscles default to empty', () {
      final json = jsonEncode([
        {
          'id': '33333333-3333-4333-8333-333333333333',
          'name': 'Pull-Up',
          'measurementType': 'bodyweight',
          'prominence': 'common',
          'primaryMuscles': ['lats'],
        },
      ]);
      final entry = CanonicalSeedCatalog.parse(json).single;
      expect(entry.measurementType, const MeasurementType.bodyweight());
      expect(entry.secondaryMuscles, isEmpty);
    });
  });

  group('CanonicalSeedCatalog.parse — rejections', () {
    test('rejects a non-array root', () {
      expect(
        () => CanonicalSeedCatalog.parse('{"not":"an array"}'),
        throwsA(isA<DeserializationError>()),
      );
    });

    test('rejects an unknown measurementType', () {
      final json = catalog([benchEntry(measurementType: 'isometricMystery')]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
        throwsA(isA<DeserializationError>()),
      );
    });

    test('rejects an unknown prominence', () {
      final json = catalog([benchEntry(prominence: 'mainstream')]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
        throwsA(
          isA<DeserializationError>()
              .having((e) => e.discriminator, 'discriminator', 'mainstream'),
        ),
      );
    });

    test('rejects an unknown muscle group', () {
      final json = catalog([
        benchEntry(primaryMuscles: const ['kneecaps']),
      ]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
        throwsA(isA<DeserializationError>()),
      );
    });

    test('rejects an entry with a missing id', () {
      final json = jsonEncode([
        {
          'name': 'No Id',
          'measurementType': 'repBased',
          'prominence': 'common',
          'primaryMuscles': ['chest'],
        },
      ]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
        throwsA(
          isA<DeserializationError>()
              .having((e) => e.field, 'field', 'id'),
        ),
      );
    });

    test('rejects a null id', () {
      final json = jsonEncode([
        {
          'id': null,
          'name': 'Null Id',
          'measurementType': 'repBased',
          'prominence': 'common',
          'primaryMuscles': ['chest'],
        },
      ]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
        throwsA(isA<DeserializationError>()),
      );
    });

    test('rejects duplicate ids', () {
      final json = catalog([
        benchEntry(),
        benchEntry(name: 'Duplicate Id Different Name'),
      ]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'duplicate_seed_id',
          ),
        ),
      );
    });

    test('rejects overlapping primary/secondary muscles', () {
      final json = catalog([
        benchEntry(
          primaryMuscles: const ['chest', 'triceps'],
          secondaryMuscles: const ['triceps'],
        ),
      ]);
      expect(
        () => CanonicalSeedCatalog.parse(json),
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
}
