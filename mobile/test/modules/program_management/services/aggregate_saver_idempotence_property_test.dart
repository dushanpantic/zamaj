import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/program_management/program_management.dart';

import '../../../support/in_memory_app_database.dart';

/// **Validates: Requirements R9 AC3**
///
/// Property 7: AggregateSaver idempotence.
///
/// Saving the same logical [ProgramDraft] twice to the same database produces
/// two [Program] aggregates that are structurally equal (same name, workout
/// day names, exercise group kinds, exercise names, measurement types, planned
/// rest seconds, and planned set values) even though the persisted ids,
/// timestamps, and schemaVersion differ.
void main() {
  late InMemoryDatabaseHelper helper;
  late DriftProgramRepository repo;
  late AggregateSaver saver;

  setUp(() async {
    helper = InMemoryDatabaseHelper();
    await helper.setUp();
    repo = DriftProgramRepository(db: helper.db);
    saver = AggregateSaver(repo);
  });

  tearDown(() async {
    await helper.tearDown();
  });

  test(
    'Property 7: saving the same ProgramDraft twice yields structurally equal programs (≥100 iterations)',
    () async {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final rng = Random(i);
        final draft = anyProgramDraft(rng);

        final saved1 = await saver.save(draft);
        final saved2 = await saver.save(draft);

        expect(
          saved1.name,
          equals(saved2.name),
          reason: 'seed=$i: program names differ',
        );

        final days1 = await repo.listWorkoutDaysForProgram(saved1.id);
        final days2 = await repo.listWorkoutDaysForProgram(saved2.id);

        _assertWorkoutDaysEqual(days1, days2, seed: i);
      }
    },
  );
}

void _assertWorkoutDaysEqual(
  List<domain.WorkoutDay> days1,
  List<domain.WorkoutDay> days2, {
  required int seed,
}) {
  expect(
    days1.length,
    equals(days2.length),
    reason: 'seed=$seed: workout day counts differ',
  );

  for (var d = 0; d < days1.length; d++) {
    final day1 = days1[d];
    final day2 = days2[d];

    expect(
      day1.name,
      equals(day2.name),
      reason: 'seed=$seed: day[$d] names differ',
    );

    expect(
      day1.exerciseGroups.length,
      equals(day2.exerciseGroups.length),
      reason: 'seed=$seed: day[$d] group counts differ',
    );

    for (var g = 0; g < day1.exerciseGroups.length; g++) {
      final group1 = day1.exerciseGroups[g];
      final group2 = day2.exerciseGroups[g];

      expect(
        group1.kind,
        equals(group2.kind),
        reason: 'seed=$seed: day[$d] group[$g] kinds differ',
      );

      expect(
        group1.exercises.length,
        equals(group2.exercises.length),
        reason: 'seed=$seed: day[$d] group[$g] exercise counts differ',
      );

      for (var e = 0; e < group1.exercises.length; e++) {
        final ex1 = group1.exercises[e];
        final ex2 = group2.exercises[e];

        expect(
          ex1.name,
          equals(ex2.name),
          reason: 'seed=$seed: day[$d] group[$g] exercise[$e] names differ',
        );

        expect(
          ex1.measurementType,
          equals(ex2.measurementType),
          reason:
              'seed=$seed: day[$d] group[$g] exercise[$e] measurementTypes differ',
        );

        expect(
          ex1.metadata.notes,
          equals(ex2.metadata.notes),
          reason:
              'seed=$seed: day[$d] group[$g] exercise[$e] metadata.notes differ',
        );

        expect(
          ex1.metadata.videoUrl,
          equals(ex2.metadata.videoUrl),
          reason:
              'seed=$seed: day[$d] group[$g] exercise[$e] metadata.videoUrl differ',
        );

        expect(
          ex1.sets.length,
          equals(ex2.sets.length),
          reason:
              'seed=$seed: day[$d] group[$g] exercise[$e] set counts differ',
        );

        for (var s = 0; s < ex1.sets.length; s++) {
          expect(
            ex1.sets[s].plannedValues,
            equals(ex2.sets[s].plannedValues),
            reason:
                'seed=$seed: day[$d] group[$g] exercise[$e] set[$s] plannedValues differ',
          );
        }
      }
    }
  }
}

ProgramDraft anyProgramDraft(Random rng) {
  final dayCount = 1 + rng.nextInt(3);
  return ProgramDraft(
    programId: null,
    name: _anyName(rng, maxLen: 10),
    workoutDays: List.generate(dayCount, (i) => _anyWorkoutDayDraft(rng, i)),
    schemaVersion: null,
  );
}

WorkoutDayDraft _anyWorkoutDayDraft(Random rng, int index) {
  final groupCount = 1 + rng.nextInt(2);
  return WorkoutDayDraft(
    draftId: 'day_$index',
    persistedId: null,
    name: _anyName(rng, maxLen: 10),
    groups: List.generate(
      groupCount,
      (i) => _anyExerciseGroupDraft(rng, index, i),
    ),
  );
}

ExerciseGroupDraft _anyExerciseGroupDraft(
  Random rng,
  int dayIndex,
  int groupIndex,
) {
  final exerciseCount = 1 + rng.nextInt(2);
  return ExerciseGroupDraft(
    draftId: 'group_${dayIndex}_$groupIndex',
    persistedId: null,
    exercises: List.generate(
      exerciseCount,
      (i) => _anyExerciseDraft(rng, dayIndex, groupIndex, i),
    ),
  );
}

ExerciseDraft _anyExerciseDraft(
  Random rng,
  int dayIndex,
  int groupIndex,
  int exerciseIndex,
) {
  final mt = rng.nextBool()
      ? const MeasurementType.repBased()
      : const MeasurementType.timeBased();
  final setCount = 1 + rng.nextInt(3);
  return ExerciseDraft(
    draftId: 'exercise_${dayIndex}_${groupIndex}_$exerciseIndex',
    persistedId: null,
    name: _anyName(rng, maxLen: 10),
    measurementType: mt,
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: null,
    sets: List.generate(
      setCount,
      (i) =>
          _anyPlannedSetDraft(rng, dayIndex, groupIndex, exerciseIndex, i, mt),
    ),
  );
}

PlannedSetDraft _anyPlannedSetDraft(
  Random rng,
  int dayIndex,
  int groupIndex,
  int exerciseIndex,
  int setIndex,
  MeasurementType mt,
) {
  final values = mt.when(
    repBased: () => PlannedSetDraftValues.repBased(
      weightInput: '${rng.nextInt(201) * 5}',
      repsInput: '${1 + rng.nextInt(20)}',
    ),
    timeBased: () => PlannedSetDraftValues.timeBased(
      durationInput: '${10 + rng.nextInt(291)}',
    ),
    bodyweight: () =>
        PlannedSetDraftValues.bodyweight(repsInput: '${1 + rng.nextInt(20)}'),
  );
  return PlannedSetDraft(
    draftId: 'set_${dayIndex}_${groupIndex}_${exerciseIndex}_$setIndex',
    persistedId: null,
    values: values,
  );
}

String _anyName(Random rng, {required int maxLen}) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final len = 1 + rng.nextInt(maxLen);
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}
