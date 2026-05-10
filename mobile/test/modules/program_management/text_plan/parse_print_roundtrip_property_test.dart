import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/services/text_plan/parse_result.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_pretty_printer.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

import '../../../support/program_management_generators.dart';

/// Validates: Requirements R10 AC1
///
/// Property 1: parse → print → parse = parse.
///
/// For any valid PlanDraft, pretty-printing it and re-parsing the result
/// must yield a draft equal to the original (warnings excluded).
void main() {
  test('Property 1: parse → print → parse = parse (≥100 iterations)', () {
    const iterations = 100;

    for (var i = 0; i < iterations; i++) {
      final seed = i;
      final rng = Random(seed);
      final original = anyPlanDraft(rng);

      final printed = PlanPrettyPrinter.print(original);
      final result = TextPlanParser.parse(printed);

      expect(
        result,
        isA<PlanParseSuccess>(),
        reason:
            'seed=$seed: parse failed after print\n'
            'printed text:\n$printed',
      );

      final reparsed = (result as PlanParseSuccess).draft;
      final originalStripped = _stripWarnings(original);
      final reparsedStripped = _stripWarnings(reparsed);

      expect(
        reparsedStripped,
        equals(originalStripped),
        reason:
            'seed=$seed: re-parsed draft differs from original\n'
            'printed text:\n$printed',
      );
    }
  });
}

PlanDraft _stripWarnings(PlanDraft draft) {
  return PlanDraft(
    programName: draft.programName,
    workoutDays: draft.workoutDays.map(_stripDayWarnings).toList(),
  );
}

PlanDraftWorkoutDay _stripDayWarnings(PlanDraftWorkoutDay day) {
  return PlanDraftWorkoutDay(
    name: day.name,
    groups: day.groups.map(_stripGroupWarnings).toList(),
  );
}

PlanDraftGroup _stripGroupWarnings(PlanDraftGroup group) {
  return PlanDraftGroup(
    exercises: group.exercises.map(_stripExerciseWarnings).toList(),
  );
}

PlanDraftExercise _stripExerciseWarnings(PlanDraftExercise exercise) {
  return PlanDraftExercise(
    draftId: exercise.draftId,
    name: exercise.name,
    plannedRestSeconds: exercise.plannedRestSeconds,
    notes: exercise.notes,
    videoUrl: exercise.videoUrl,
    sets: exercise.sets,
    warnings: const <PlanParseWarning>[],
  );
}
