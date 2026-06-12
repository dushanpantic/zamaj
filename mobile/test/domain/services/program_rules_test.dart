import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/services/program_rules.dart';

Matcher _throwsCode(String code) => throwsA(
  isA<ValidationError>().having((e) => e.invariant, 'invariant', code),
);

void main() {
  group('ProgramRules.checkWeightKg', () {
    test('accepts in-range half-kg values', () {
      expect(() => ProgramRules.checkWeightKg(0), returnsNormally);
      expect(() => ProgramRules.checkWeightKg(2.5), returnsNormally);
      expect(() => ProgramRules.checkWeightKg(1000), returnsNormally);
    });
    test('rejects out-of-range', () {
      expect(
        () => ProgramRules.checkWeightKg(-1),
        _throwsCode('weight_out_of_range'),
      );
      expect(
        () => ProgramRules.checkWeightKg(1000.5),
        _throwsCode('weight_out_of_range'),
      );
    });
    test('rejects non-half-kg', () {
      expect(
        () => ProgramRules.checkWeightKg(2.3),
        _throwsCode('weight_not_half_kg'),
      );
    });
  });

  group('ProgramRules.checkReps', () {
    test('accepts 0..999', () {
      expect(() => ProgramRules.checkReps(0), returnsNormally);
      expect(() => ProgramRules.checkReps(999), returnsNormally);
    });
    test('rejects out-of-range', () {
      expect(
        () => ProgramRules.checkReps(-1),
        _throwsCode('reps_out_of_range'),
      );
      expect(
        () => ProgramRules.checkReps(1000),
        _throwsCode('reps_out_of_range'),
      );
    });
  });

  group('ProgramRules.checkDurationSeconds', () {
    test('accepts 0..3600', () {
      expect(() => ProgramRules.checkDurationSeconds(0), returnsNormally);
      expect(() => ProgramRules.checkDurationSeconds(3600), returnsNormally);
    });
    test('rejects out-of-range', () {
      expect(
        () => ProgramRules.checkDurationSeconds(-1),
        _throwsCode('duration_out_of_range'),
      );
      expect(
        () => ProgramRules.checkDurationSeconds(3601),
        _throwsCode('duration_out_of_range'),
      );
    });
  });

  group('ProgramRules.checkRestSeconds', () {
    test('accepts 0..3600', () {
      expect(() => ProgramRules.checkRestSeconds(0), returnsNormally);
      expect(() => ProgramRules.checkRestSeconds(3600), returnsNormally);
    });
    test('rejects out-of-range', () {
      expect(
        () => ProgramRules.checkRestSeconds(3601),
        _throwsCode('rest_out_of_range'),
      );
    });
  });

  group('ProgramRules.checkSetCount', () {
    test('accepts 1..20', () {
      expect(() => ProgramRules.checkSetCount(1), returnsNormally);
      expect(() => ProgramRules.checkSetCount(20), returnsNormally);
    });
    test('rejects below and above', () {
      expect(
        () => ProgramRules.checkSetCount(0),
        _throwsCode('set_count_too_low'),
      );
      expect(
        () => ProgramRules.checkSetCount(21),
        _throwsCode('set_count_too_high'),
      );
    });
  });

  group('ProgramRules name checks', () {
    test('exercise name max 80', () {
      expect(() => ProgramRules.checkExerciseName('A' * 80), returnsNormally);
      expect(
        () => ProgramRules.checkExerciseName('A' * 81),
        _throwsCode('name_too_long'),
      );
      expect(
        () => ProgramRules.checkExerciseName('   '),
        _throwsCode('name_too_short'),
      );
    });
    test('workout day name max 100', () {
      expect(
        () => ProgramRules.checkWorkoutDayName('A' * 100),
        returnsNormally,
      );
      expect(
        () => ProgramRules.checkWorkoutDayName('A' * 101),
        _throwsCode('name_too_long'),
      );
    });
    test('program name max 100', () {
      expect(() => ProgramRules.checkProgramName('A' * 100), returnsNormally);
      expect(
        () => ProgramRules.checkProgramName('A' * 101),
        _throwsCode('name_too_long'),
      );
      expect(
        () => ProgramRules.checkProgramName(''),
        _throwsCode('name_too_short'),
      );
    });
  });

  group('ProgramRules.checkVideoUrl', () {
    test('accepts null, empty, and absolute http(s) urls', () {
      expect(() => ProgramRules.checkVideoUrl(null), returnsNormally);
      expect(() => ProgramRules.checkVideoUrl(''), returnsNormally);
      expect(
        () => ProgramRules.checkVideoUrl('https://example.com/v'),
        returnsNormally,
      );
      expect(
        () => ProgramRules.checkVideoUrl('http://example.com/v'),
        returnsNormally,
      );
    });
    test('rejects too-long, non-absolute, and non-http schemes', () {
      expect(
        () => ProgramRules.checkVideoUrl('https://e.com/${'a' * 2048}'),
        _throwsCode('url_too_long'),
      );
      expect(
        () => ProgramRules.checkVideoUrl('not-absolute'),
        _throwsCode('url_not_absolute'),
      );
      expect(
        () => ProgramRules.checkVideoUrl('ftp://example.com'),
        _throwsCode('url_scheme_not_http_https'),
      );
    });
  });

  group('ProgramRules.checkNotes', () {
    test('accepts null and up to 2000 chars', () {
      expect(() => ProgramRules.checkNotes(null), returnsNormally);
      expect(() => ProgramRules.checkNotes('A' * 2000), returnsNormally);
    });
    test('rejects over 2000 chars', () {
      expect(
        () => ProgramRules.checkNotes('A' * 2001),
        _throwsCode('notes_too_long'),
      );
    });
  });
}
