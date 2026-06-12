import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

void main() {
  group('ActualSetValues.matches(MeasurementType)', () {
    const repBased = ActualSetValues.repBased(weightKg: 100, reps: 5);
    const timeBased = ActualSetValues.timeBased(durationSeconds: 60);
    const bodyweight = ActualSetValues.bodyweight(reps: 12);

    test('repBased values match the repBased measurement type', () {
      expect(repBased.matches(const MeasurementType.repBased()), isTrue);
    });

    test('repBased values reject the other measurement types', () {
      expect(repBased.matches(const MeasurementType.timeBased()), isFalse);
      expect(repBased.matches(const MeasurementType.bodyweight()), isFalse);
    });

    test('timeBased values match the timeBased measurement type', () {
      expect(timeBased.matches(const MeasurementType.timeBased()), isTrue);
    });

    test('timeBased values reject the other measurement types', () {
      expect(timeBased.matches(const MeasurementType.repBased()), isFalse);
      expect(timeBased.matches(const MeasurementType.bodyweight()), isFalse);
    });

    test('bodyweight values match the bodyweight measurement type', () {
      expect(bodyweight.matches(const MeasurementType.bodyweight()), isTrue);
    });

    test('bodyweight values reject the other measurement types', () {
      expect(bodyweight.matches(const MeasurementType.repBased()), isFalse);
      expect(bodyweight.matches(const MeasurementType.timeBased()), isFalse);
    });
  });
}
