import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/set_input_adjustment.dart';

PlannedSetDraft _repSet(String weight, String reps, {String id = 'x'}) =>
    PlannedSetDraft(
      draftId: id,
      persistedId: null,
      values: PlannedSetDraftValues.repBased(
        weightInput: weight,
        repsInput: reps,
      ),
    );

void main() {
  group('SetInputAdjustment.bumpReps', () {
    test('bumps a fixed rep count', () {
      expect(SetInputAdjustment.bumpReps('5', 1), '6');
    });

    test('bumps a hyphen range preserving its shape', () {
      expect(SetInputAdjustment.bumpReps('6-8', 1), '7-9');
    });

    test('bumps an en-dash range preserving its separator', () {
      expect(SetInputAdjustment.bumpReps('6–8', 1), '7–9');
    });

    test('clamps each rep at zero', () {
      expect(SetInputAdjustment.bumpReps('0-1', -1), '0-0');
    });

    test('is a no-op on a blank input', () {
      expect(SetInputAdjustment.bumpReps('', 1), '');
    });

    test('is a no-op on a non-numeric input', () {
      expect(SetInputAdjustment.bumpReps('abc', 1), 'abc');
    });
  });

  group('SetInputAdjustment.bumpWeight', () {
    test('bumps a weight input', () {
      expect(SetInputAdjustment.bumpWeight('100', 2.5), '102.5');
    });

    test('snaps to half-kg and clamps at zero', () {
      expect(SetInputAdjustment.bumpWeight('2', -2.5), '0');
    });

    test('is a no-op on a blank input', () {
      expect(SetInputAdjustment.bumpWeight('', 2.5), '');
    });

    test('is a no-op on a non-numeric input', () {
      expect(SetInputAdjustment.bumpWeight('abc', 2.5), 'abc');
    });
  });

  group('SetInputAdjustment.bumpDuration', () {
    test('bumps a duration input', () {
      expect(SetInputAdjustment.bumpDuration('60', 5), '65');
    });

    test('clamps at zero', () {
      expect(SetInputAdjustment.bumpDuration('3', -5), '0');
    });

    test('is a no-op on a blank input', () {
      expect(SetInputAdjustment.bumpDuration('', 5), '');
    });
  });

  group('SetInputAdjustment.formatWeight', () {
    test('drops the trailing decimal for whole values', () {
      expect(SetInputAdjustment.formatWeight(100.0), '100');
    });

    test('keeps the half-kg decimal', () {
      expect(SetInputAdjustment.formatWeight(102.5), '102.5');
    });
  });

  group('SetInputAdjustment.areUniform', () {
    test('is true when every set holds equal values', () {
      final sets = [
        _repSet('100', '5', id: 'a'),
        _repSet('100', '5', id: 'b'),
        _repSet('100', '5', id: 'c'),
      ];
      expect(SetInputAdjustment.areUniform(sets), isTrue);
    });

    test('is false when any set differs', () {
      final sets = [
        _repSet('80', '5', id: 'a'),
        _repSet('90', '5', id: 'b'),
        _repSet('100', '5', id: 'c'),
      ];
      expect(SetInputAdjustment.areUniform(sets), isFalse);
    });

    test('is true for a single set', () {
      expect(SetInputAdjustment.areUniform([_repSet('100', '5')]), isTrue);
    });

    test('is true for blank-but-equal sets', () {
      final sets = [_repSet('', '', id: 'a'), _repSet('', '', id: 'b')];
      expect(SetInputAdjustment.areUniform(sets), isTrue);
    });

    test('is true for an empty list', () {
      expect(SetInputAdjustment.areUniform(const []), isTrue);
    });

    test('compares time-based values', () {
      const sets = [
        PlannedSetDraft(
          draftId: 'a',
          persistedId: null,
          values: PlannedSetDraftValues.timeBased(durationInput: '60'),
        ),
        PlannedSetDraft(
          draftId: 'b',
          persistedId: null,
          values: PlannedSetDraftValues.timeBased(durationInput: '90'),
        ),
      ];
      expect(SetInputAdjustment.areUniform(sets), isFalse);
    });
  });
}
