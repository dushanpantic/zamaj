import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('SetValueFormatter.formatPlanned', () {
    test('null planned renders the em-dash placeholder', () {
      expect(
        SetValueFormatter.formatPlanned(null, const MeasurementType.repBased()),
        '—',
      );
    });

    test('rep-based fixed target shows weight (kg) × reps', () {
      expect(
        SetValueFormatter.formatPlanned(
          PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 8),
          ),
          const MeasurementType.repBased(),
        ),
        '100kg × 8',
      );
    });

    test('rep-based range target shows the rep range', () {
      expect(
        SetValueFormatter.formatPlanned(
          PlannedSetValues.repBased(
            weightKg: 60,
            repTarget: RepTarget.range(minReps: 8, maxReps: 12),
          ),
          const MeasurementType.repBased(),
        ),
        '60kg × 8-12',
      );
    });

    test('rep-based half-kg weight keeps one decimal', () {
      expect(
        SetValueFormatter.formatPlanned(
          PlannedSetValues.repBased(
            weightKg: 97.5,
            repTarget: RepTarget.fixed(reps: 5),
          ),
          const MeasurementType.repBased(),
        ),
        '97.5kg × 5',
      );
    });

    test('time-based without weight shows seconds only', () {
      expect(
        SetValueFormatter.formatPlanned(
          const PlannedSetValues.timeBased(durationSeconds: 30),
          const MeasurementType.timeBased(),
        ),
        '30s',
      );
    });

    test('time-based with weight shows weight (kg) × seconds', () {
      expect(
        SetValueFormatter.formatPlanned(
          const PlannedSetValues.timeBased(durationSeconds: 30, weightKg: 20),
          const MeasurementType.timeBased(),
        ),
        '20kg × 30s',
      );
    });

    test('bodyweight fixed target shows × reps', () {
      expect(
        SetValueFormatter.formatPlanned(
          PlannedSetValues.bodyweight(repTarget: RepTarget.fixed(reps: 10)),
          const MeasurementType.bodyweight(),
        ),
        '× 10',
      );
    });

    test('bodyweight range target shows × rep range', () {
      expect(
        SetValueFormatter.formatPlanned(
          PlannedSetValues.bodyweight(
            repTarget: RepTarget.range(minReps: 8, maxReps: 12),
          ),
          const MeasurementType.bodyweight(),
        ),
        '× 8-12',
      );
    });
  });

  group('SetValueFormatter.formatActual', () {
    test('rep-based shows weight × reps without a kg suffix', () {
      expect(
        SetValueFormatter.formatActual(
          const ActualSetValues.repBased(weightKg: 100, reps: 8),
        ),
        '100 × 8',
      );
    });

    test('rep-based half-kg weight keeps one decimal', () {
      expect(
        SetValueFormatter.formatActual(
          const ActualSetValues.repBased(weightKg: 97.5, reps: 5),
        ),
        '97.5 × 5',
      );
    });

    test('time-based without weight shows seconds only', () {
      expect(
        SetValueFormatter.formatActual(
          const ActualSetValues.timeBased(durationSeconds: 45),
        ),
        '45s',
      );
    });

    test(
      'time-based with weight shows weight × seconds without a kg suffix',
      () {
        expect(
          SetValueFormatter.formatActual(
            const ActualSetValues.timeBased(durationSeconds: 45, weightKg: 20),
          ),
          '20 × 45s',
        );
      },
    );

    test('bodyweight shows × reps', () {
      expect(
        SetValueFormatter.formatActual(
          const ActualSetValues.bodyweight(reps: 12),
        ),
        '× 12',
      );
    });
  });
}
