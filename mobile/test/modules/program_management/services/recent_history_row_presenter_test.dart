import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/recent_history_row_presenter.dart';

CapHistoryEntry _entry({
  required List<PlannedSetValues> planned,
  required List<ActualSetValues> actual,
  required bool isCapped,
}) => CapHistoryEntry(
  date: DateTime(2026, 6, 12),
  programId: 'p1',
  sourceWorkoutDayName: 'Day',
  plannedSets: planned,
  actualSets: actual,
  isCapped: isCapped,
);

List<PlannedSetValues> _repRange(int count) => [
  for (var i = 0; i < count; i++)
    PlannedSetValues.repBased(
      weightKg: 100,
      repTarget: RepTarget.range(minReps: 8, maxReps: 12),
    ),
];

List<ActualSetValues> _reps(List<int> reps) => [
  for (final r in reps) ActualSetValues.repBased(weightKg: 100, reps: r),
];

List<PlannedSetValues> _plannedAt(double weight, int count) => [
  for (var i = 0; i < count; i++)
    PlannedSetValues.repBased(
      weightKg: weight,
      repTarget: RepTarget.range(minReps: 8, maxReps: 12),
    ),
];

List<ActualSetValues> _repsAt(double weight, List<int> reps) => [
  for (final r in reps) ActualSetValues.repBased(weightKg: weight, reps: r),
];

void main() {
  group('RecentHistoryRowPresenter.present', () {
    test('capped rep-range entry: bright actuals + range cap tooltip', () {
      final planned = _repRange(3);
      final view = RecentHistoryRowPresenter.present(
        _entry(planned: planned, actual: _reps([12, 12, 12]), isCapped: true),
      );

      expect(
        view.plannedText,
        SetValueFormatter.formatPlanned(
          planned.first,
          const MeasurementType.repBased(),
        ),
      );
      expect(view.actualsText, '12 · 12 · 12');
      expect(view.actualsAreMuted, isFalse);
      expect(view.isCapped, isTrue);
      expect(view.capDescription, 'top of range');
      expect(view.capTooltip, 'Capped — top of range');
    });

    test('capped fixed-rep entry: "hit target"', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: [
            PlannedSetValues.repBased(
              weightKg: 100,
              repTarget: RepTarget.fixed(reps: 10),
            ),
          ],
          actual: _reps([10]),
          isCapped: true,
        ),
      );

      expect(view.capDescription, 'hit target');
      expect(view.capTooltip, 'Capped — hit target');
    });

    test('capped time-based entry: "hit time" and "45s" actuals', () {
      final planned = [const PlannedSetValues.timeBased(durationSeconds: 45)];
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: planned,
          actual: const [ActualSetValues.timeBased(durationSeconds: 45)],
          isCapped: true,
        ),
      );

      expect(
        view.plannedText,
        SetValueFormatter.formatPlanned(
          planned.first,
          const MeasurementType.timeBased(),
        ),
      );
      expect(view.actualsText, '45s');
      expect(view.capDescription, 'hit time');
      expect(view.capTooltip, 'Capped — hit time');
    });

    test('capped bodyweight range entry: "top of range" and rep actuals', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: [
            PlannedSetValues.bodyweight(
              repTarget: RepTarget.range(minReps: 8, maxReps: 10),
            ),
          ],
          actual: const [ActualSetValues.bodyweight(reps: 10)],
          isCapped: true,
        ),
      );

      expect(view.actualsText, '10');
      expect(view.capDescription, 'top of range');
    });

    test('non-capped off-day entry: no marker, bright actuals', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: _repRange(3),
          actual: _reps([12, 12, 11]),
          isCapped: false,
        ),
      );

      expect(view.actualsText, '12 · 12 · 11');
      expect(view.actualsAreMuted, isFalse);
      expect(view.isCapped, isFalse);
      expect(view.capDescription, isNull);
      expect(view.capTooltip, isNull);
    });

    test('skipped-in-session entry: muted "—" actuals, no marker', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(planned: _repRange(3), actual: const [], isCapped: false),
      );

      expect(view.actualsText, '—');
      expect(view.actualsAreMuted, isTrue);
      expect(view.isCapped, isFalse);
      expect(view.capTooltip, isNull);
    });

    test('partial entry: lists only the logged sets, not muted', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(planned: _repRange(3), actual: _reps([12, 12]), isCapped: false),
      );

      expect(view.actualsText, '12 · 12');
      expect(view.actualsAreMuted, isFalse);
      expect(view.capDescription, isNull);
    });

    test('empty planned (defensive): planned reads "—"', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(planned: const [], actual: _reps([12]), isCapped: false),
      );

      expect(view.plannedText, '—');
    });

    test('capped with indeterminate target (defensive): "Capped"', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(planned: const [], actual: _reps([12]), isCapped: true),
      );

      expect(view.capDescription, 'capped');
      expect(view.capTooltip, 'Capped');
    });
  });

  group('RecentHistoryRowPresenter.present — actuals weight when off-plan', () {
    test('on-plan weight stays reps-only', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: _plannedAt(50, 3),
          actual: _repsAt(50, [8, 8, 8]),
          isCapped: true,
        ),
      );
      expect(view.actualsText, '8 · 8 · 8');
    });

    test('a uniform lighter weight surfaces once as a leading tag', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: _plannedAt(50, 3),
          actual: _repsAt(40, [8, 8, 8]),
          isCapped: false,
        ),
      );
      expect(view.actualsText, '@40kg 8 · 8 · 8');
    });

    test('a uniform heavier weight surfaces once as a leading tag', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: _plannedAt(50, 3),
          actual: _repsAt(55, [8, 8, 8]),
          isCapped: true,
        ),
      );
      expect(view.actualsText, '@55kg 8 · 8 · 8');
    });

    test('a fractional off-plan weight keeps its decimal', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: _plannedAt(50, 1),
          actual: _repsAt(12.5, [8]),
          isCapped: false,
        ),
      );
      expect(view.actualsText, '@12.5kg 8');
    });

    test('weights varying between sets annotate each set', () {
      final view = RecentHistoryRowPresenter.present(
        _entry(
          planned: _plannedAt(50, 3),
          actual: const [
            ActualSetValues.repBased(weightKg: 40, reps: 8),
            ActualSetValues.repBased(weightKg: 42.5, reps: 8),
            ActualSetValues.repBased(weightKg: 45, reps: 8),
          ],
          isCapped: false,
        ),
      );
      expect(view.actualsText, '40 × 8 · 42.5 × 8 · 45 × 8');
    });
  });
}
