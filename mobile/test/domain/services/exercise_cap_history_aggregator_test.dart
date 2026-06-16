import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

// ---------------------------------------------------------------------------
// Planned / actual builders — concise per-set values for the cap predicate.
// ---------------------------------------------------------------------------

PlannedSetValues _repRange(int min, int max, {double weight = 80}) =>
    PlannedSetValues.repBased(
      weightKg: weight,
      repTarget: RepTarget.range(minReps: min, maxReps: max),
    );

PlannedSetValues _repFixed(int reps, {double weight = 80}) =>
    PlannedSetValues.repBased(
      weightKg: weight,
      repTarget: RepTarget.fixed(reps: reps),
    );

PlannedSetValues _bwRange(int min, int max) =>
    PlannedSetValues.bodyweight(repTarget: RepTarget.range(minReps: min, maxReps: max));

ActualSetValues _actReps(int reps, {double weight = 80}) =>
    ActualSetValues.repBased(weightKg: weight, reps: reps);

ActualSetValues _actBodyweight(int reps) =>
    ActualSetValues.bodyweight(reps: reps);

PlannedSetValues _time(int seconds) =>
    PlannedSetValues.timeBased(durationSeconds: seconds);

ActualSetValues _actTime(int seconds) =>
    ActualSetValues.timeBased(durationSeconds: seconds);

void main() {
  group('ExerciseCapHistoryAggregator.isCapped — rep-based & bodyweight', () {
    test('rep-range caps when every working set reaches the top (AC1)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repRange(10, 12), _repRange(10, 12), _repRange(10, 12)],
          actualSets: [_actReps(12), _actReps(12), _actReps(12)],
        ),
        isTrue,
      );
    });

    test('rep-range does not cap when one set falls short (AC1)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repRange(10, 12), _repRange(10, 12), _repRange(10, 12)],
          actualSets: [_actReps(12), _actReps(12), _actReps(11)],
        ),
        isFalse,
      );
    });

    test('fixed target caps when every set meets the target (AC2)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repFixed(12), _repFixed(12), _repFixed(12)],
          actualSets: [_actReps(12), _actReps(12), _actReps(12)],
        ),
        isTrue,
      );
    });

    test('fixed target does not cap when one set falls short (AC2)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repFixed(12), _repFixed(12), _repFixed(12)],
          actualSets: [_actReps(12), _actReps(12), _actReps(11)],
        ),
        isFalse,
      );
    });

    test('reps exceeding the ceiling still cap (AC4)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repRange(10, 12), _repRange(10, 12), _repRange(10, 12)],
          actualSets: [_actReps(13), _actReps(12), _actReps(14)],
        ),
        isTrue,
      );
    });

    test('bodyweight uses the rep-ceiling rule and caps (AC5)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_bwRange(8, 10), _bwRange(8, 10), _bwRange(8, 10)],
          actualSets: [_actBodyweight(10), _actBodyweight(10), _actBodyweight(10)],
        ),
        isTrue,
      );
    });

    test('bodyweight does not cap when one set falls short (AC5)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_bwRange(8, 10), _bwRange(8, 10), _bwRange(8, 10)],
          actualSets: [_actBodyweight(10), _actBodyweight(9), _actBodyweight(10)],
        ),
        isFalse,
      );
    });

    test('descending vary-by-set (drop set) generally does not cap (AC6)', () {
      // Planned 8 / 6 / 4 fixed; logged 8 / 5 / 4 — the middle set misses its
      // own ceiling of 6.
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repFixed(8), _repFixed(6), _repFixed(4)],
          actualSets: [_actReps(8), _actReps(5), _actReps(4)],
        ),
        isFalse,
      );
    });

    test('ascending pyramid caps when every set meets its own ceiling (AC6)', () {
      // Planned 8-10 / 6-8 / 4-6; logged 10 / 8 / 6 — each hits its own top.
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repRange(8, 10), _repRange(6, 8), _repRange(4, 6)],
          actualSets: [_actReps(10), _actReps(8), _actReps(6)],
        ),
        isTrue,
      );
    });

    test('an unfinished session (fewer sets logged than planned) does not cap', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repRange(10, 12), _repRange(10, 12), _repRange(10, 12)],
          actualSets: [_actReps(12), _actReps(12)],
        ),
        isFalse,
      );
    });
  });

  group('ExerciseCapHistoryAggregator.isCapped — time-based', () {
    test('caps when every hold meets the planned duration (AC3)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_time(45), _time(45), _time(45)],
          actualSets: [_actTime(45), _actTime(50), _actTime(45)],
        ),
        isTrue,
      );
    });

    test('does not cap when one hold falls short of the duration (AC3)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_time(45), _time(45), _time(45)],
          actualSets: [_actTime(45), _actTime(40), _actTime(45)],
        ),
        isFalse,
      );
    });

    test('a duration exceeding the planned hold still caps (AC4)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_time(45), _time(45), _time(45)],
          actualSets: [_actTime(50), _actTime(60), _actTime(45)],
        ),
        isTrue,
      );
    });
  });
}
