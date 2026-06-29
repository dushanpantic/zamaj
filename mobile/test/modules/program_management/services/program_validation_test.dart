import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_state.dart';
import 'package:zamaj/modules/program_management/services/program_validation.dart';

void main() {
  group('ProgramValidation.validateProgramName (unified 100 limit)', () {
    test('100 chars is accepted on create and edit', () {
      expect(
        ProgramValidation.validateProgramName('A' * 100, isCreate: true),
        isA<Valid<String>>(),
      );
      expect(
        ProgramValidation.validateProgramName('A' * 100, isCreate: false),
        isA<Valid<String>>(),
      );
    });

    test('120 chars is rejected on create (the former 120 limit is gone)', () {
      final r = ProgramValidation.validateProgramName(
        'A' * 120,
        isCreate: true,
      );
      expect((r as Invalid<String>).reason, 'name_too_long');
    });

    test('101 chars is rejected', () {
      expect(
        ProgramValidation.validateProgramName('A' * 101, isCreate: true),
        isA<Invalid<String>>(),
      );
    });

    test('empty is name_too_short', () {
      final r = ProgramValidation.validateProgramName('  ', isCreate: false);
      expect((r as Invalid<String>).reason, 'name_too_short');
    });
  });

  group('ProgramDraftValidation unified 100 limit', () {
    test('120-char name is invalid', () {
      expect(
        ProgramDraftValidation.compute(name: 'A' * 120).isNameValid,
        isFalse,
      );
    });

    test('100-char name is valid', () {
      expect(
        ProgramDraftValidation.compute(name: 'A' * 100).isNameValid,
        isTrue,
      );
    });
  });

  group('ProgramValidation delegates bounds to ProgramRules', () {
    test('rep-based set weight above max is weight_out_of_range', () {
      final r = ProgramValidation.validateRepBasedSet(
        weightInput: '2000',
        repsInput: '8',
      );
      expect((r as Invalid).reason, 'weight_out_of_range');
    });

    test('rep-based set non-half-kg weight is weight_not_half_kg', () {
      final r = ProgramValidation.validateRepBasedSet(
        weightInput: '2.3',
        repsInput: '8',
      );
      expect((r as Invalid).reason, 'weight_not_half_kg');
    });

    test('duration above max is duration_out_of_range', () {
      final r = ProgramValidation.validateTimeBasedSet('3601');
      expect((r as Invalid).reason, 'duration_out_of_range');
    });

    test('rest above max is rest_out_of_range', () {
      final r = ProgramValidation.validatePlannedRest('3601');
      expect((r as Invalid).reason, 'rest_out_of_range');
    });

    test('set count above max is set_count_too_high', () {
      final r = ProgramValidation.validateSetCount(21);
      expect((r as Invalid).reason, 'set_count_too_high');
    });

    test('video url with non-http scheme is url_scheme_not_http_https', () {
      final r = ProgramValidation.validateVideoUrl('ftp://example.com');
      expect((r as Invalid).reason, 'url_scheme_not_http_https');
    });
  });

  group('ProgramValidation.parseRepTarget uses RepTarget.parse', () {
    test('en-dash range parses to a range target', () {
      final r = ProgramValidation.parseRepTarget('6–8');
      expect(
        (r as Valid<RepTarget>).value,
        RepTarget.range(minReps: 6, maxReps: 8),
      );
    });

    test('out-of-range reps is reps_out_of_range', () {
      final r = ProgramValidation.parseRepTarget('1000');
      expect((r as Invalid<RepTarget>).reason, 'reps_out_of_range');
    });
  });
}
