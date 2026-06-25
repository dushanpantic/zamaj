import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('ActualToPlannedSets.fromActual', () {
    test('a rep-based set becomes a fixed-rep planned set', () {
      final planned = ActualToPlannedSets.fromActual(
        const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );

      expect(
        planned,
        PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 5),
        ),
      );
    });

    test('a bodyweight set becomes a fixed-rep planned set with no weight', () {
      final planned = ActualToPlannedSets.fromActual(
        const ActualSetValues.bodyweight(reps: 12),
      );

      expect(
        planned,
        PlannedSetValues.bodyweight(repTarget: RepTarget.fixed(reps: 12)),
      );
    });

    test('a timed set with weight becomes a planned hold with weight', () {
      final planned = ActualToPlannedSets.fromActual(
        const ActualSetValues.timeBased(durationSeconds: 45, weightKg: 20),
      );

      expect(
        planned,
        const PlannedSetValues.timeBased(durationSeconds: 45, weightKg: 20),
      );
    });

    test(
      'a timed set without weight becomes a planned hold without weight',
      () {
        final planned = ActualToPlannedSets.fromActual(
          const ActualSetValues.timeBased(durationSeconds: 60),
        );

        expect(planned, const PlannedSetValues.timeBased(durationSeconds: 60));
      },
    );
  });

  group('ActualToPlannedSets.fromActuals', () {
    test('preserves order, one planned set per logged set', () {
      final planned = ActualToPlannedSets.fromActuals(const [
        ActualSetValues.repBased(weightKg: 100, reps: 5),
        ActualSetValues.repBased(weightKg: 100, reps: 5),
        ActualSetValues.repBased(weightKg: 100, reps: 4),
      ]);

      expect(planned, [
        PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 5),
        ),
        PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 5),
        ),
        PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 4),
        ),
      ]);
    });

    test('an empty list yields an empty prescription', () {
      expect(ActualToPlannedSets.fromActuals(const []), isEmpty);
    });
  });
}
