import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/clock.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/persistence/persistence.dart'
    hide WorkoutDay, Exercise, WorkoutSet;
import 'package:zamaj/modules/program_management/program_management.dart';
import 'package:zamaj/modules/program_management/services/text_plan/parse_result.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_pretty_printer.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

import '../../../support/in_memory_app_database.dart';
import '../../../support/program_management_generators.dart';

/// Validates: Requirements R10 AC4
///
/// Property 4: save → load → print → parse = parse.
///
/// For any valid PlanDraft, converting to a ProgramDraft, saving via
/// AggregateSaver, loading back via ProgramRepository, reconstructing a
/// PlanDraft, pretty-printing, and re-parsing must yield a draft equal to
/// the original (warnings excluded).
void main() {
  test(
    'Property 4: save → load → print → parse = parse (≥100 iterations)',
    () async {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final seed = i;
        final rng = Random(seed);
        final original = anyPlanDraft(rng);

        final helper = InMemoryDatabaseHelper();
        await helper.setUp();
        try {
          final repo = DriftProgramRepository(db: helper.db);
          final saver = AggregateSaver(repo);

          final programDraft = PlanDraftToAggregate.convert(
            original,
            idGenerator: const Uuid(),
            clock: const AppClock(),
          );

          final savedProgram = await saver.save(programDraft);

          final workoutDayIds = savedProgram.workoutDayIds;
          final loadedDays = <WorkoutDay>[];
          for (final dayId in workoutDayIds) {
            final day = await repo.getWorkoutDay(dayId);
            if (day != null) loadedDays.add(day);
          }

          final reconstructed = _reconstructPlanDraft(
            savedProgram.name,
            loadedDays,
          );

          final printed = PlanPrettyPrinter.print(reconstructed);
          final result = TextPlanParser.parse(printed);

          expect(
            result,
            isA<PlanParseSuccess>(),
            reason:
                'seed=$seed: parse failed after save→load→print\n'
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
        } finally {
          await helper.tearDown();
        }
      }
    },
  );
}

PlanDraft _reconstructPlanDraft(String programName, List<WorkoutDay> days) {
  return PlanDraft(
    programName: programName,
    workoutDays: days.asMap().entries.map((dayEntry) {
      final dayIndex = dayEntry.key;
      final day = dayEntry.value;
      return PlanDraftWorkoutDay(
        name: day.name,
        groups: day.exerciseGroups.asMap().entries.map((groupEntry) {
          final groupIndex = groupEntry.key;
          final group = groupEntry.value;
          return PlanDraftGroup(
            exercises: group.exercises.asMap().entries.map((exEntry) {
              final exerciseIndex = exEntry.key;
              final exercise = exEntry.value;
              final draftId =
                  'exercise_${dayIndex}_${groupIndex}_$exerciseIndex';
              return PlanDraftExercise(
                draftId: draftId,
                name: exercise.name,
                plannedRestSeconds: exercise.plannedRestSeconds,
                notes: exercise.metadata.notes,
                videoUrl: exercise.metadata.videoUrl,
                sets: _groupSetsIntoPlannedSets(exercise.sets),
                warnings: const <PlanParseWarning>[],
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList(),
  );
}

List<PlanDraftSet> _groupSetsIntoPlannedSets(List<WorkoutSet> sets) {
  if (sets.isEmpty) return [];

  final result = <PlanDraftSet>[];
  var i = 0;
  while (i < sets.length) {
    final current = sets[i];
    final values = current.plannedValues;
    var count = 1;

    while (i + count < sets.length) {
      final next = sets[i + count];
      if (!_plannedValuesEqual(values, next.plannedValues)) break;
      count++;
    }

    result.add(_toPlanDraftSet(values, count));
    i += count;
  }
  return result;
}

bool _plannedValuesEqual(PlannedSetValues a, PlannedSetValues b) {
  return switch ((a, b)) {
    (
      PlannedRepBased(weightKg: final wA, reps: final rA),
      PlannedRepBased(weightKg: final wB, reps: final rB),
    ) =>
      wA == wB && rA == rB,
    (
      PlannedTimeBased(durationSeconds: final dA),
      PlannedTimeBased(durationSeconds: final dB),
    ) =>
      dA == dB,
    _ => false,
  };
}

PlanDraftSet _toPlanDraftSet(PlannedSetValues values, int count) {
  return switch (values) {
    PlannedRepBased(:final weightKg, :final reps) => PlanDraftSet.repBased(
      count: count,
      reps: reps,
      weightKg: weightKg,
    ),
    PlannedTimeBased(:final durationSeconds) => PlanDraftSet.timeBased(
      count: count,
      durationSeconds: durationSeconds,
    ),
  };
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
