// Validates: Requirements R13 AC1

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/planned_summary_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('PlannedSummaryFormatter.summarize', () {
    test('empty sets list returns "0 sets"', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: const [],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '0 sets');
    });

    test('single rep-based set returns "<kg>kg 1×<reps>"', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [_repSet(0, weightKg: 100, reps: 8)],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '100kg 1×8');
    });

    test('all-equal rep-based sets return "<kg>kg <n>×<reps>"', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [
          _repSet(0, weightKg: 100, reps: 8),
          _repSet(1, weightKg: 100, reps: 8),
          _repSet(2, weightKg: 100, reps: 8),
          _repSet(3, weightKg: 100, reps: 8),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '100kg 4×8');
    });

    test('mixed rep-based sets fall back to "<n> sets"', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [
          _repSet(0, weightKg: 100, reps: 8),
          _repSet(1, weightKg: 100, reps: 6),
          _repSet(2, weightKg: 95, reps: 8),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '3 sets');
    });

    test('all-equal time-based sets return "<n>×<duration>s"', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.timeBased(),
        sets: [
          _timeSet(0, durationSeconds: 30),
          _timeSet(1, durationSeconds: 30),
          _timeSet(2, durationSeconds: 30),
          _timeSet(3, durationSeconds: 30),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '4×30s');
    });

    test('mixed time-based sets fall back to "<n> sets"', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.timeBased(),
        sets: [
          _timeSet(0, durationSeconds: 30),
          _timeSet(1, durationSeconds: 45),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '2 sets');
    });

    test('integer kg drops decimal (100.0 → "100")', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [
          _repSet(0, weightKg: 100, reps: 5),
          _repSet(1, weightKg: 100, reps: 5),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '100kg 2×5');
    });

    test('fractional kg keeps one decimal (97.5 → "97.5")', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [
          _repSet(0, weightKg: 97.5, reps: 5),
          _repSet(1, weightKg: 97.5, reps: 5),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '97.5kg 2×5');
    });

    test('zero kg drops decimal ("0kg ...")', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [
          _repSet(0, weightKg: 0, reps: 10),
          _repSet(1, weightKg: 0, reps: 10),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '0kg 2×10');
    });

    test('out-of-order positions still compare against sorted-first', () {
      final exercise = _exercise(
        measurementType: const MeasurementType.repBased(),
        sets: [
          _repSet(2, weightKg: 100, reps: 8),
          _repSet(0, weightKg: 100, reps: 8),
          _repSet(1, weightKg: 100, reps: 8),
        ],
      );
      expect(PlannedSummaryFormatter.summarize(exercise), '100kg 3×8');
    });
  });
}

Exercise _exercise({
  required MeasurementType measurementType,
  required List<WorkoutSet> sets,
}) {
  final now = DateTime.utc(2025);
  return Exercise(
    id: 'ex-1',
    exerciseGroupId: 'g-1',
    position: 0,
    name: 'Bench Press',
    measurementType: measurementType,
    metadata: const ExerciseMetadata(),
    sets: sets,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

WorkoutSet _repSet(
  int position, {
  required double weightKg,
  required int reps,
}) {
  final now = DateTime.utc(2025);
  return WorkoutSet(
    id: 'ws-$position',
    exerciseId: 'ex-1',
    position: position,
    measurementType: const MeasurementType.repBased(),
    plannedValues: PlannedSetValues.repBased(
      weightKg: weightKg,
      repTarget: RepTarget.fixed(reps: reps),
    ),
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

WorkoutSet _timeSet(int position, {required int durationSeconds}) {
  final now = DateTime.utc(2025);
  return WorkoutSet(
    id: 'ws-$position',
    exerciseId: 'ex-1',
    position: position,
    measurementType: const MeasurementType.timeBased(),
    plannedValues: PlannedSetValues.timeBased(durationSeconds: durationSeconds),
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}
