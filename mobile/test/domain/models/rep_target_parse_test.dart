import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';

void main() {
  group('RepTarget.parse', () {
    test('a single integer is a fixed target', () {
      expect(RepTarget.parse('8'), RepTarget.fixed(reps: 8));
    });

    test('a hyphen range is a range target', () {
      expect(RepTarget.parse('6-8'), RepTarget.range(minReps: 6, maxReps: 8));
    });

    test('an en-dash range is a range target', () {
      expect(RepTarget.parse('6–8'), RepTarget.range(minReps: 6, maxReps: 8));
    });

    test('spaces around the separator are tolerated', () {
      expect(RepTarget.parse('6 - 8'), RepTarget.range(minReps: 6, maxReps: 8));
    });

    test('equal bounds collapse to a fixed target', () {
      expect(RepTarget.parse('8-8'), RepTarget.fixed(reps: 8));
    });

    test('reversed bounds are rejected as range_invalid', () {
      expect(
        () => RepTarget.parse('8-6'),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'range_invalid',
          ),
        ),
      );
    });

    test('an out-of-range value is rejected as reps_out_of_range', () {
      expect(
        () => RepTarget.parse('1000'),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'reps_out_of_range',
          ),
        ),
      );
    });

    test('a non-whole value is rejected as reps_not_whole', () {
      expect(
        () => RepTarget.parse('8.5'),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'reps_not_whole',
          ),
        ),
      );
    });

    test('non-numeric input is rejected as reps_invalid', () {
      expect(
        () => RepTarget.parse('abc'),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'reps_invalid',
          ),
        ),
      );
    });

    test('empty input is rejected as reps_invalid', () {
      expect(
        () => RepTarget.parse('   '),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'reps_invalid',
          ),
        ),
      );
    });
  });
}
