import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/increment_rules.dart';

void main() {
  group('IncrementRules.weightSteps', () {
    test('weight ≤ 10 → ±1 (boundary inclusive)', () {
      expect(IncrementRules.weightSteps(0), [-1, 1]);
      expect(IncrementRules.weightSteps(5), [-1, 1]);
      expect(IncrementRules.weightSteps(10), [-1, 1]);
    });

    test('weight > 10 → ±2.5', () {
      expect(IncrementRules.weightSteps(10.5), [-2.5, 2.5]);
      expect(IncrementRules.weightSteps(40), [-2.5, 2.5]);
      expect(IncrementRules.weightSteps(140.0), [-2.5, 2.5]);
    });
  });

  group('IncrementRules.bumpWeight', () {
    test('clamps to zero', () {
      expect(IncrementRules.bumpWeight(2, -5), 0);
      expect(IncrementRules.bumpWeight(0, -2.5), 0);
    });

    test('rounds to nearest 0.5 to satisfy domain invariant', () {
      // 2.7 + 1 = 3.7 → 3.5
      expect(IncrementRules.bumpWeight(2.7, 1), 3.5);
      // 95 + 2.5 = 97.5
      expect(IncrementRules.bumpWeight(95, 2.5), 97.5);
    });
  });

  group('IncrementRules.roundHalfKg', () {
    test('snaps up to the nearest half-kg', () {
      expect(IncrementRules.roundHalfKg(2.26), 2.5);
    });

    test('snaps down to the nearest half-kg', () {
      expect(IncrementRules.roundHalfKg(2.24), 2.0);
    });

    test('rounds the midpoint away from zero, matching bumpWeight', () {
      expect(IncrementRules.roundHalfKg(2.25), 2.5);
      // Same rule bumpWeight relies on, so the two can never diverge.
      expect(
        IncrementRules.roundHalfKg(2.7 + 1),
        IncrementRules.bumpWeight(2.7, 1),
      );
    });

    test(
      'passes negatives through unclamped (clamping is bumpWeight\'s job)',
      () {
        expect(IncrementRules.roundHalfKg(-2.26), -2.5);
      },
    );
  });

  group('IncrementRules.bumpReps', () {
    test('clamps to zero', () {
      expect(IncrementRules.bumpReps(0, -1), 0);
      expect(IncrementRules.bumpReps(3, -5), 0);
    });

    test('increments by delta', () {
      expect(IncrementRules.bumpReps(8, 1), 9);
      expect(IncrementRules.bumpReps(10, -3), 7);
    });
  });

  group('IncrementRules.bumpDuration', () {
    test('clamps to zero', () {
      expect(IncrementRules.bumpDuration(3, -10), 0);
    });

    test('increments by delta', () {
      expect(IncrementRules.bumpDuration(30, 5), 35);
    });
  });
}
