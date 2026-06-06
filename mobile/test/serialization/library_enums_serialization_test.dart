import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';

void main() {
  group('Prominence JSON', () {
    test('round-trips every value', () {
      for (final value in Prominence.values) {
        expect(Prominence.fromJson(value.toJson()), equals(value));
      }
    });

    test('serializes to its bare name', () {
      expect(Prominence.common.toJson(), equals('common'));
      expect(Prominence.specialized.toJson(), equals('specialized'));
    });

    test('rejects an unknown value via the deserialization wrapper', () {
      expect(
        () => Prominence.fromJson('mainstream'),
        throwsA(
          isA<DeserializationError>()
              .having((e) => e.discriminator, 'discriminator', 'mainstream'),
        ),
      );
    });
  });

  group('LibrarySource JSON', () {
    test('round-trips every value', () {
      for (final value in LibrarySource.values) {
        expect(LibrarySource.fromJson(value.toJson()), equals(value));
      }
    });

    test('serializes to its bare name', () {
      expect(LibrarySource.user.toJson(), equals('user'));
      expect(LibrarySource.canonicalSeed.toJson(), equals('canonicalSeed'));
    });

    test('rejects an unknown value via the deserialization wrapper', () {
      expect(
        () => LibrarySource.fromJson('imported'),
        throwsA(isA<DeserializationError>()),
      );
    });
  });

  group('MuscleGroup JSON', () {
    test('round-trips every value', () {
      for (final value in MuscleGroup.values) {
        expect(MuscleGroup.fromJson(value.toJson()), equals(value));
      }
    });

    test('toJson is the bare enum name', () {
      for (final value in MuscleGroup.values) {
        expect(value.toJson(), equals(value.name));
      }
    });

    test('rejects an unknown value via the deserialization wrapper', () {
      expect(
        () => MuscleGroup.fromJson('not_a_muscle'),
        throwsA(
          isA<DeserializationError>()
              .having((e) => e.discriminator, 'discriminator', 'not_a_muscle'),
        ),
      );
    });
  });
}
