import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/services/set_value_input_mapper.dart';

void main() {
  group('SetValueInputMapper.parse', () {
    group('rep-based', () {
      const mt = MeasurementType.repBased();

      test('parses weight and reps', () {
        final values = SetValueInputMapper.parse(
          measurementType: mt,
          weightText: '82.5',
          repsText: '5',
          durationText: '',
        );
        expect(values, const ActualSetValues.repBased(weightKg: 82.5, reps: 5));
      });

      test('rounds weight up to the nearest half-kg', () {
        final values = SetValueInputMapper.parse(
          measurementType: mt,
          weightText: '62.3',
          repsText: '8',
          durationText: '',
        );
        expect(values, const ActualSetValues.repBased(weightKg: 62.5, reps: 8));
      });

      test('rounds weight down to the nearest half-kg', () {
        final values = SetValueInputMapper.parse(
          measurementType: mt,
          weightText: '62.1',
          repsText: '8',
          durationText: '',
        );
        expect(values, const ActualSetValues.repBased(weightKg: 62, reps: 8));
      });

      test('returns null on empty weight', () {
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '',
            repsText: '5',
            durationText: '',
          ),
          isNull,
        );
      });

      test('returns null on negative values', () {
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '-5',
            repsText: '5',
            durationText: '',
          ),
          isNull,
        );
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '80',
            repsText: '-1',
            durationText: '',
          ),
          isNull,
        );
      });
    });

    group('time-based', () {
      const mt = MeasurementType.timeBased();

      test('parses seconds with no weight', () {
        final values = SetValueInputMapper.parse(
          measurementType: mt,
          weightText: '',
          repsText: '',
          durationText: '45',
        );
        expect(values, const ActualSetValues.timeBased(durationSeconds: 45));
      });

      test('parses seconds with a rounded optional weight', () {
        final values = SetValueInputMapper.parse(
          measurementType: mt,
          weightText: '20.2',
          repsText: '',
          durationText: '30',
        );
        expect(
          values,
          const ActualSetValues.timeBased(durationSeconds: 30, weightKg: 20),
        );
      });

      test('returns null on invalid seconds', () {
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '',
            repsText: '',
            durationText: '',
          ),
          isNull,
        );
      });

      test('returns null on negative optional weight', () {
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '-1',
            repsText: '',
            durationText: '30',
          ),
          isNull,
        );
      });
    });

    group('bodyweight', () {
      const mt = MeasurementType.bodyweight();

      test('parses reps', () {
        final values = SetValueInputMapper.parse(
          measurementType: mt,
          weightText: '',
          repsText: '12',
          durationText: '',
        );
        expect(values, const ActualSetValues.bodyweight(reps: 12));
      });

      test('returns null on negative or empty reps', () {
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '',
            repsText: '-2',
            durationText: '',
          ),
          isNull,
        );
        expect(
          SetValueInputMapper.parse(
            measurementType: mt,
            weightText: '',
            repsText: '',
            durationText: '',
          ),
          isNull,
        );
      });
    });
  });

  group('SetValueInputMapper.seed', () {
    test('rep-based seeds weight and reps, no duration', () {
      final fields = SetValueInputMapper.seed(
        const ActualSetValues.repBased(weightKg: 82.5, reps: 5),
        const MeasurementType.repBased(),
      );
      expect(fields, (weight: '82.5', reps: '5', duration: ''));
    });

    test('rep-based seeds an integer weight without a decimal', () {
      final fields = SetValueInputMapper.seed(
        const ActualSetValues.repBased(weightKg: 80, reps: 5),
        const MeasurementType.repBased(),
      );
      expect(fields.weight, '80');
    });

    test('time-based seeds duration and leaves weight empty when null', () {
      final fields = SetValueInputMapper.seed(
        const ActualSetValues.timeBased(durationSeconds: 30),
        const MeasurementType.timeBased(),
      );
      expect(fields, (weight: '', reps: '', duration: '30'));
    });

    test('bodyweight seeds reps only', () {
      final fields = SetValueInputMapper.seed(
        const ActualSetValues.bodyweight(reps: 12),
        const MeasurementType.bodyweight(),
      );
      expect(fields, (weight: '', reps: '12', duration: ''));
    });

    test('a null value seeds zero defaults for the measurement type', () {
      final fields = SetValueInputMapper.seed(
        null,
        const MeasurementType.repBased(),
      );
      expect(fields, (weight: '0', reps: '0', duration: ''));
    });
  });
}
