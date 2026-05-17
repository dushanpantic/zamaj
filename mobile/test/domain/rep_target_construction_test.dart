import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';

void main() {
  group('RepTarget construction invariants', () {
    test('fixed rejects negative reps', () {
      expect(
        () => RepTarget.fixed(reps: -1),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'reps_non_negative',
          ),
        ),
      );
    });

    test('range rejects negative minReps', () {
      expect(
        () => RepTarget.range(minReps: -1, maxReps: 5),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'reps_non_negative',
          ),
        ),
      );
    });

    test('range rejects max < min', () {
      expect(
        () => RepTarget.range(minReps: 8, maxReps: 6),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'range_min_le_max',
          ),
        ),
      );
    });

    test('range rejects min == max (use fixed instead)', () {
      expect(
        () => RepTarget.range(minReps: 6, maxReps: 6),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'range_distinct',
          ),
        ),
      );
    });

    test('fixed accepts zero', () {
      final t = RepTarget.fixed(reps: 0);
      expect(t, isA<RepTargetFixed>());
    });

    test('range accepts valid bounds', () {
      final t = RepTarget.range(minReps: 6, maxReps: 8);
      expect(t, isA<RepTargetRange>());
    });
  });

  group('RepTarget JSON round-trip', () {
    test('fixed', () {
      final t = RepTarget.fixed(reps: 10);
      expect(RepTarget.fromJson(t.toJson()), equals(t));
    });

    test('range', () {
      final t = RepTarget.range(minReps: 6, maxReps: 8);
      expect(RepTarget.fromJson(t.toJson()), equals(t));
    });
  });
}
