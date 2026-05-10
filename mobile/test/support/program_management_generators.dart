import 'dart:math';

import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_pretty_printer.dart';

PlanDraft anyPlanDraft(Random rng) {
  final dayCount = 1 + rng.nextInt(3);
  final days = List.generate(dayCount, (dayIndex) {
    return _anyWorkoutDay(rng, dayIndex);
  });
  return PlanDraft(programName: _anyPlanName(rng), workoutDays: days);
}

PlanDraftWorkoutDay _anyWorkoutDay(Random rng, int dayIndex) {
  final groupCount = 1 + rng.nextInt(3);
  final groups = List.generate(groupCount, (groupIndex) {
    return _anyGroup(rng, dayIndex, groupIndex);
  });
  return PlanDraftWorkoutDay(name: _anyDayName(rng), groups: groups);
}

PlanDraftGroup _anyGroup(Random rng, int dayIndex, int groupIndex) {
  final exerciseCount = 1 + rng.nextInt(2);
  final exercises = List.generate(exerciseCount, (exerciseIndex) {
    final draftId = 'exercise_${dayIndex}_${groupIndex}_$exerciseIndex';
    return _anyExercise(rng, draftId);
  });
  return PlanDraftGroup(exercises: exercises);
}

PlanDraftExercise _anyExercise(Random rng, String draftId) {
  final setCount = 1 + rng.nextInt(3);
  final isRepBased = rng.nextBool();
  final sets = List.generate(setCount, (_) {
    return isRepBased ? _anyRepBasedSet(rng) : _anyTimeBasedSet(rng);
  });
  final hasRest = rng.nextBool();
  final plannedRestSeconds = hasRest ? 1 + rng.nextInt(3600) : null;
  return PlanDraftExercise(
    draftId: draftId,
    name: _anyExerciseName(rng),
    plannedRestSeconds: plannedRestSeconds,
    notes: null,
    videoUrl: null,
    sets: sets,
    warnings: const <PlanParseWarning>[],
  );
}

PlanDraftSet _anyRepBasedSet(Random rng) {
  final halfKgs = rng.nextInt(2001);
  final weightKg = halfKgs * 0.5;
  final reps = rng.nextInt(1000);
  final count = 1 + rng.nextInt(10);
  return PlanDraftSet.repBased(count: count, reps: reps, weightKg: weightKg);
}

PlanDraftSet _anyTimeBasedSet(Random rng) {
  final durationSeconds = rng.nextInt(3601);
  final count = 1 + rng.nextInt(10);
  return PlanDraftSet.timeBased(count: count, durationSeconds: durationSeconds);
}

String _anyPlanName(Random rng) {
  return _anyName(rng, 50, _planNameChars);
}

String _anyDayName(Random rng) {
  return _anyName(rng, 40, _dayNameChars);
}

String _anyExerciseName(Random rng) {
  return _anyName(rng, 40, _exerciseNameChars);
}

String _anyName(Random rng, int maxLen, String chars) {
  final len = 1 + rng.nextInt(maxLen);
  final buf = StringBuffer();
  for (var i = 0; i < len; i++) {
    buf.writeCharCode(chars.codeUnitAt(rng.nextInt(chars.length)));
  }
  final raw = buf.toString().trim();
  if (raw.isEmpty) return 'A';
  return raw;
}

const _planNameChars = 'abcdefghijklmnopqrstuvwyzABCDEFGHIJKLMNOPQRSTUVWYZ ';

const _dayNameChars = 'abcdefghijklmnopqrstuvwyzABCDEFGHIJKLMNOPQRSTUVWYZ ';

const _exerciseNameChars =
    'abcdefghijklmnopqrstuvwyzABCDEFGHIJKLMNOPQRSTUVWYZ ';

/// Generates a mix of valid and invalid plan text strings for PBT.
///
/// Roughly 25% of outputs are unparseable (empty, orphan set line, unknown
/// keyword). The remaining 75% are structurally valid plan texts.
String anyPlanText(Random rng) {
  if (rng.nextInt(4) == 0) {
    return _anyUnparseablePlanText(rng);
  }
  return _anyValidPlanText(rng);
}

/// Generates a valid, parseable plan text string via [PlanPrettyPrinter].
String anyValidPlanText(Random rng) {
  final draft = anyPlanDraft(rng);
  return PlanPrettyPrinter.print(draft);
}

String _anyValidPlanText(Random rng) {
  final buffer = StringBuffer();
  buffer.writeln(_anyPlanName(rng));
  buffer.writeln();

  final dayCount = 1 + rng.nextInt(3);
  for (var d = 0; d < dayCount; d++) {
    buffer.writeln('Day ${_anyDayLabel(rng, d)}');
    buffer.writeln();

    final groupCount = 1 + rng.nextInt(3);
    for (var g = 0; g < groupCount; g++) {
      final isSuperset = rng.nextBool();
      if (isSuperset) {
        buffer.writeln('Superset:');
        final exerciseCount = 2 + rng.nextInt(2);
        for (var e = 0; e < exerciseCount; e++) {
          buffer.writeln(_anyExerciseNameText(rng));
          final setCount = 1 + rng.nextInt(3);
          for (var s = 0; s < setCount; s++) {
            buffer.writeln(_anySetLine(rng));
          }
        }
      } else {
        buffer.writeln(_anyExerciseNameText(rng));
        final setCount = 1 + rng.nextInt(3);
        for (var s = 0; s < setCount; s++) {
          buffer.writeln(_anySetLine(rng));
        }
      }
      buffer.writeln();
    }
  }

  return buffer.toString().trimRight();
}

String _anyUnparseablePlanText(Random rng) {
  switch (rng.nextInt(3)) {
    case 0:
      return '';
    case 1:
      return '4x8 100kg';
    default:
      return 'unknown_keyword_xyz_${rng.nextInt(1000)}';
  }
}

String _anyDayLabel(Random rng, int index) {
  const labels = ['Upper', 'Lower', 'Push', 'Pull', 'Legs', 'A', 'B', 'C'];
  if (rng.nextBool()) {
    return '${index + 1}';
  }
  return labels[rng.nextInt(labels.length)];
}

String _anyExerciseNameText(Random rng) {
  const names = [
    'Bench Press',
    'Squat',
    'Deadlift',
    'Overhead Press',
    'Barbell Row',
    'Pull Up',
    'Dip',
    'Leg Press',
    'Romanian Deadlift',
    'Incline Press',
  ];
  return names[rng.nextInt(names.length)];
}

String _anySetLine(Random rng) {
  final sets = 1 + rng.nextInt(5);
  final reps = 1 + rng.nextInt(15);
  final useWeight = rng.nextBool();
  final useRest = rng.nextBool();

  final buffer = StringBuffer('${sets}x$reps');

  if (useWeight) {
    final halfKgs = rng.nextInt(401);
    final weight = halfKgs * 0.5;
    if (weight == weight.truncateToDouble()) {
      buffer.write(' ${weight.toInt()}kg');
    } else {
      buffer.write(' ${weight.toStringAsFixed(1)}kg');
    }
  }

  if (useRest) {
    final restSeconds = 30 + rng.nextInt(331);
    if (restSeconds % 60 == 0 && rng.nextBool()) {
      buffer.write(' ${restSeconds ~/ 60}m');
    } else {
      buffer.write(' ${restSeconds}s');
    }
  }

  return buffer.toString();
}

String anyUnparseablePlanText(Random rng) {
  final strategy = rng.nextInt(5);
  switch (strategy) {
    case 0:
      return '';
    case 1:
      final spaces = 1 + rng.nextInt(10);
      return ' ' * spaces;
    case 2:
      final count = 1 + rng.nextInt(5);
      final reps = 1 + rng.nextInt(20);
      return '${count}x$reps 100kg';
    case 3:
      return 'ss';
    default:
      final num = 100 + rng.nextInt(900);
      return '$num foo bar';
  }
}
