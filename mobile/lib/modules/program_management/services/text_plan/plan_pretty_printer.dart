import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';

abstract final class PlanPrettyPrinter {
  static String print(PlanDraft draft) {
    final lines = <String>[];

    lines.add(draft.programName);
    lines.add('');

    for (var dayIndex = 0; dayIndex < draft.workoutDays.length; dayIndex++) {
      final day = draft.workoutDays[dayIndex];

      if (dayIndex > 0) {
        lines.add('');
      }

      lines.add('Day ${day.name}');
      lines.add('');

      for (var groupIndex = 0; groupIndex < day.groups.length; groupIndex++) {
        final group = day.groups[groupIndex];

        if (groupIndex > 0) {
          lines.add('');
        }

        final isSuperset = group.exercises.length >= 2;
        if (isSuperset) {
          lines.add('Superset:');
        }

        for (final exercise in group.exercises) {
          lines.add(exercise.name);
          for (final set in exercise.sets) {
            lines.add(_formatSetLine(set, exercise.plannedRestSeconds));
          }
        }
      }
    }

    return lines.join('\n');
  }

  static String _formatSetLine(PlanDraftSet set, int? plannedRestSeconds) {
    final restSuffix = plannedRestSeconds != null
        ? ' ${plannedRestSeconds}s'
        : '';
    return switch (set) {
      PlanDraftSetRepBased(:final count, :final reps, :final weightKg) =>
        '${count}x$reps ${WeightFormatter.formatKg(weightKg)}kg$restSuffix',
      PlanDraftSetTimeBased(
        :final count,
        :final durationSeconds,
        :final weightKg,
      ) =>
        weightKg == null
            ? '${count}x${durationSeconds}s$restSuffix'
            : '${count}x${durationSeconds}s ${WeightFormatter.formatKg(weightKg)}kg$restSuffix',
    };
  }
}
