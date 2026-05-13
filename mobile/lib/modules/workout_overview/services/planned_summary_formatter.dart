import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

abstract final class PlannedSummaryFormatter {
  static String summarize(Exercise plannedExercise) {
    final sets = List<WorkoutSet>.of(plannedExercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sets.isEmpty) return '0 sets';

    final first = sets.first.plannedValues;
    final allSame = sets.every((s) => s.plannedValues == first);

    if (!allSame) return '${sets.length} sets';

    return switch (first) {
      PlannedRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sets.length}×$reps',
      PlannedTimeBased(:final durationSeconds) =>
        '${sets.length}×${durationSeconds}s',
    };
  }
}
