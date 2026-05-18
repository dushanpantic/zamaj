import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/program_management/services/text_plan/parse_result.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_error.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

const _goldenDir = 'test/modules/program_management/text_plan/golden';

String _readGolden(String name) => File('$_goldenDir/$name').readAsStringSync();

void main() {
  group('TextPlanParser — rep-based plan', () {
    test('parses a rep-based plan from fixture', () {
      final input = _readGolden('rep_based_plan.txt');
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);

      final draft = success.draft;
      expect(draft.programName, equals('Push Pull Legs'));
      expect(draft.workoutDays, hasLength(1));

      final day = draft.workoutDays.first;
      expect(day.name, equals('1'));
      expect(day.groups, hasLength(1));

      final group = day.groups.first;
      expect(group.exercises, hasLength(1));

      final exercise = group.exercises.first;
      expect(exercise.draftId, equals('exercise_0_0_0'));
      expect(exercise.name, equals('Bench Press'));
      expect(exercise.plannedRestSeconds, isNull);
      expect(exercise.sets, hasLength(1));

      final set = exercise.sets.first;
      expect(set, isA<PlanDraftSetRepBased>());
      final repSet = set as PlanDraftSetRepBased;
      expect(repSet.count, equals(4));
      expect(repSet.repTarget, equals(RepTarget.fixed(reps: 8)));
      expect(repSet.weightKg, equals(100.0));
    });
  });

  group('TextPlanParser — rep-range plan', () {
    test('parses ASCII-dash range (4x6-8)', () {
      final input = _readGolden('rep_range_plan.txt');
      final result = TextPlanParser.parse(input);
      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);
      final set =
          success
                  .draft
                  .workoutDays
                  .first
                  .groups
                  .first
                  .exercises
                  .first
                  .sets
                  .first
              as PlanDraftSetRepBased;
      expect(set.count, equals(4));
      expect(set.repTarget, equals(RepTarget.range(minReps: 6, maxReps: 8)));
      expect(set.weightKg, equals(60.0));
    });

    test('parses en-dash range (4x6–8)', () {
      final input = _readGolden('rep_range_endash_plan.txt');
      final result = TextPlanParser.parse(input);
      expect(result, isA<PlanParseSuccess>());
      final set =
          (result as PlanParseSuccess)
                  .draft
                  .workoutDays
                  .first
                  .groups
                  .first
                  .exercises
                  .first
                  .sets
                  .first
              as PlanDraftSetRepBased;
      expect(set.repTarget, equals(RepTarget.range(minReps: 6, maxReps: 8)));
    });

    test('inverted range (4x8-6) emits a warning and skips the set', () {
      const input = 'Plan\n\nDay 1\nBench Press\n4x8-6 60kg\n';
      final result = TextPlanParser.parse(input);
      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isNotEmpty);
      final exercise =
          success.draft.workoutDays.first.groups.first.exercises.first;
      expect(exercise.sets, isEmpty);
    });
  });

  group('TextPlanParser — time-based plan', () {
    test('parses a time-based plan from fixture', () {
      final input = _readGolden('time_based_plan.txt');
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);

      final draft = success.draft;
      expect(draft.programName, equals('Core Work'));
      expect(draft.workoutDays, hasLength(1));

      final day = draft.workoutDays.first;
      expect(day.name, equals('1'));
      expect(day.groups, hasLength(1));

      final group = day.groups.first;
      expect(group.exercises, hasLength(1));

      final exercise = group.exercises.first;
      expect(exercise.draftId, equals('exercise_0_0_0'));
      expect(exercise.name, equals('Plank'));
      expect(exercise.plannedRestSeconds, isNull);
      expect(exercise.sets, hasLength(1));

      final set = exercise.sets.first;
      expect(set, isA<PlanDraftSetTimeBased>());
      final timeSet = set as PlanDraftSetTimeBased;
      expect(timeSet.count, equals(3));
      expect(timeSet.durationSeconds, equals(60));
    });
  });

  group('TextPlanParser — superset plan', () {
    test('parses a superset plan from fixture', () {
      final input = _readGolden('superset_plan.txt');
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);

      final draft = success.draft;
      expect(draft.programName, equals('Upper Body'));
      expect(draft.workoutDays, hasLength(1));

      final day = draft.workoutDays.first;
      expect(day.name, equals('1'));
      expect(day.groups, hasLength(1));

      final group = day.groups.first;
      expect(group.exercises, hasLength(2));

      final bench = group.exercises[0];
      expect(bench.draftId, equals('exercise_0_0_0'));
      expect(bench.name, equals('Bench Press'));
      expect(bench.sets, hasLength(1));
      final benchSet = bench.sets.first as PlanDraftSetRepBased;
      expect(benchSet.count, equals(4));
      expect(benchSet.repTarget, equals(RepTarget.fixed(reps: 8)));
      expect(benchSet.weightKg, equals(100.0));

      final rows = group.exercises[1];
      expect(rows.draftId, equals('exercise_0_0_1'));
      expect(rows.name, equals('Rows'));
      expect(rows.sets, hasLength(1));
      final rowsSet = rows.sets.first as PlanDraftSetRepBased;
      expect(rowsSet.count, equals(4));
      expect(rowsSet.repTarget, equals(RepTarget.fixed(reps: 8)));
      expect(rowsSet.weightKg, equals(80.0));
    });
  });

  group('TextPlanParser — mixed plan with rest token', () {
    test('parses 4x8 100kg 2m and converts rest to seconds', () {
      final input = _readGolden('mixed_plan_with_rest.txt');
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);

      final draft = success.draft;
      expect(draft.programName, equals('Strength Program'));

      final exercise = draft.workoutDays.first.groups.first.exercises.first;
      expect(exercise.name, equals('Bench Press'));
      expect(exercise.plannedRestSeconds, equals(120));

      final set = exercise.sets.first as PlanDraftSetRepBased;
      expect(set.count, equals(4));
      expect(set.repTarget, equals(RepTarget.fixed(reps: 8)));
      expect(set.weightKg, equals(100.0));
    });

    test('rest in seconds (90s) is stored as-is', () {
      const input = 'Strength\n\nDay 1\nSquat\n5x5 80kg 90s\n';
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      final exercise =
          success.draft.workoutDays.first.groups.first.exercises.first;
      expect(exercise.plannedRestSeconds, equals(90));
    });
  });

  group('TextPlanParser — bodyweight', () {
    test('parses "4x8 bw" as a bodyweight set with no weight', () {
      const input = 'Calisthenics\n\nDay 1\nPushups\n4x8 bw\n';
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);

      final exercise =
          success.draft.workoutDays.first.groups.first.exercises.first;
      expect(exercise.name, equals('Pushups'));

      final set = exercise.sets.first as PlanDraftSetBodyweight;
      expect(set.count, equals(4));
      expect(set.repTarget, equals(RepTarget.fixed(reps: 8)));
    });

    test('parses "3x6-10 bw 90s" as bodyweight with range and rest', () {
      const input = 'Calisthenics\n\nDay 1\nPullups\n3x6-10 bw 90s\n';
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;
      expect(success.warnings, isEmpty);

      final exercise =
          success.draft.workoutDays.first.groups.first.exercises.first;
      expect(exercise.plannedRestSeconds, equals(90));

      final set = exercise.sets.first as PlanDraftSetBodyweight;
      expect(set.count, equals(3));
      expect(set.repTarget, equals(RepTarget.range(minReps: 6, maxReps: 10)));
    });
  });

  group('TextPlanParser — orphan set line', () {
    test('set line before any day header returns orphan_set_line error', () {
      const input = '4x8 100kg\n';
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseFailure>());
      final failure = result as PlanParseFailure;
      expect(failure.error.code, equals(PlanParseErrorCode.orphanSetLine));
      expect(failure.error.line, equals(1));
      expect(failure.error.column, equals(1));
    });

    test(
      'set line after program name but before day header returns orphan_set_line error',
      () {
        const input = 'My Program\n4x8 100kg\n';
        final result = TextPlanParser.parse(input);

        expect(result, isA<PlanParseFailure>());
        final failure = result as PlanParseFailure;
        expect(failure.error.code, equals(PlanParseErrorCode.orphanSetLine));
        expect(failure.error.line, equals(2));
        expect(failure.error.column, equals(1));
      },
    );
  });

  group('TextPlanParser — unknown line', () {
    test(
      'unclassifiable line outside day scope returns unknown_line error',
      () {
        const input = 'My Program\nsome unknown line\n';
        final result = TextPlanParser.parse(input);

        expect(result, isA<PlanParseFailure>());
        final failure = result as PlanParseFailure;
        expect(failure.error.code, equals(PlanParseErrorCode.unknownLine));
        expect(failure.error.line, equals(2));
        expect(failure.error.column, equals(1));
      },
    );
  });

  group('TextPlanParser — empty and whitespace input', () {
    test('empty string returns empty_input error at line 1 column 1', () {
      final result = TextPlanParser.parse('');

      expect(result, isA<PlanParseFailure>());
      final failure = result as PlanParseFailure;
      expect(failure.error.code, equals(PlanParseErrorCode.emptyInput));
      expect(failure.error.line, equals(1));
      expect(failure.error.column, equals(1));
    });

    test('whitespace-only string returns empty_input error', () {
      final result = TextPlanParser.parse('   \n  \t  \n   ');

      expect(result, isA<PlanParseFailure>());
      final failure = result as PlanParseFailure;
      expect(failure.error.code, equals(PlanParseErrorCode.emptyInput));
      expect(failure.error.line, equals(1));
      expect(failure.error.column, equals(1));
    });

    test('single newline returns empty_input error', () {
      final result = TextPlanParser.parse('\n');

      expect(result, isA<PlanParseFailure>());
      final failure = result as PlanParseFailure;
      expect(failure.error.code, equals(PlanParseErrorCode.emptyInput));
    });
  });

  group('TextPlanParser — input size cap', () {
    test(
      'input of exactly 100,001 code units returns input_too_large error',
      () {
        final input = 'a' * 100001;
        final result = TextPlanParser.parse(input);

        expect(result, isA<PlanParseFailure>());
        final failure = result as PlanParseFailure;
        expect(failure.error.code, equals(PlanParseErrorCode.inputTooLarge));
        expect(failure.error.line, equals(1));
        expect(failure.error.column, equals(1));
      },
    );

    test('input of exactly 100,000 code units is not rejected for size', () {
      final input = 'a' * 100000;
      final result = TextPlanParser.parse(input);

      expect(
        result,
        isNot(
          isA<PlanParseFailure>().having(
            (f) => f.error.code,
            'code',
            equals(PlanParseErrorCode.inputTooLarge),
          ),
        ),
      );
    });
  });

  group('TextPlanParser — line ending tolerance', () {
    const lf = 'Push Pull Legs\n\nDay 1\nBench Press\n4x8 100kg\n';
    const crlf = 'Push Pull Legs\r\n\r\nDay 1\r\nBench Press\r\n4x8 100kg\r\n';

    test('LF line endings parse successfully', () {
      final result = TextPlanParser.parse(lf);
      expect(result, isA<PlanParseSuccess>());
    });

    test('CRLF line endings parse successfully', () {
      final result = TextPlanParser.parse(crlf);
      expect(result, isA<PlanParseSuccess>());
    });

    test('LF and CRLF produce identical ParseResult', () {
      final lfResult = TextPlanParser.parse(lf) as PlanParseSuccess;
      final crlfResult = TextPlanParser.parse(crlf) as PlanParseSuccess;

      expect(lfResult.draft, equals(crlfResult.draft));
      expect(lfResult.warnings, equals(crlfResult.warnings));
    });
  });

  group('TextPlanParser — bare-tail line (no trailing newline)', () {
    test('input without trailing newline is accepted', () {
      const input = 'Push Pull Legs\n\nDay 1\nBench Press\n4x8 100kg';
      final result = TextPlanParser.parse(input);

      expect(result, isA<PlanParseSuccess>());
      final success = result as PlanParseSuccess;

      final exercise =
          success.draft.workoutDays.first.groups.first.exercises.first;
      expect(exercise.name, equals('Bench Press'));
      expect(exercise.sets, hasLength(1));
    });

    test('bare-tail result equals result with trailing newline', () {
      const withNewline = 'Push Pull Legs\n\nDay 1\nBench Press\n4x8 100kg\n';
      const withoutNewline = 'Push Pull Legs\n\nDay 1\nBench Press\n4x8 100kg';

      final withResult = TextPlanParser.parse(withNewline) as PlanParseSuccess;
      final withoutResult =
          TextPlanParser.parse(withoutNewline) as PlanParseSuccess;

      expect(withResult.draft, equals(withoutResult.draft));
    });
  });

  group('TextPlanParser — warnings', () {
    test(
      'multiple rest tokens on one set line emits invalid_rest_token warning and last token wins',
      () {
        const input = 'My Plan\n\nDay 1\nSquat\n5x5 80kg 60s 90s\n';
        final result = TextPlanParser.parse(input);

        expect(result, isA<PlanParseSuccess>());
        final success = result as PlanParseSuccess;
        expect(success.warnings, hasLength(1));
        expect(
          success.warnings.first.code,
          equals(PlanParseWarningCode.invalidRestToken),
        );

        final exercise =
            success.draft.workoutDays.first.groups.first.exercises.first;
        expect(exercise.plannedRestSeconds, equals(90));
      },
    );

    test(
      'unrecognized trailing token emits unrecognized_trailing_token warning',
      () {
        const input = 'My Plan\n\nDay 1\nSquat\n5x5 80kg ???\n';
        final result = TextPlanParser.parse(input);

        expect(result, isA<PlanParseSuccess>());
        final success = result as PlanParseSuccess;
        expect(success.warnings, hasLength(1));
        expect(
          success.warnings.first.code,
          equals(PlanParseWarningCode.unrecognizedTrailingToken),
        );
        expect(success.warnings.first.offendingToken, equals('???'));
      },
    );
  });
}
