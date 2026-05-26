import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

class WorkoutDaySummary extends Equatable {
  const WorkoutDaySummary({
    required this.exerciseCount,
    required this.supersetCount,
    required this.warmupExerciseCount,
  });

  final int exerciseCount;
  final int supersetCount;
  final int warmupExerciseCount;

  bool get isEmpty => exerciseCount == 0 && warmupExerciseCount == 0;

  static const empty = WorkoutDaySummary(
    exerciseCount: 0,
    supersetCount: 0,
    warmupExerciseCount: 0,
  );

  static WorkoutDaySummary fromWorkoutDay(WorkoutDay day) {
    var exercises = 0;
    var supersets = 0;
    var warmups = 0;
    for (final group in day.exerciseGroups) {
      if (group.role == ExerciseGroupRole.warmup) {
        warmups += group.exercises.length;
        continue;
      }
      exercises += group.exercises.length;
      if (group.kind is SupersetKind) {
        supersets += 1;
      }
    }
    return WorkoutDaySummary(
      exerciseCount: exercises,
      supersetCount: supersets,
      warmupExerciseCount: warmups,
    );
  }

  @override
  List<Object?> get props => [
    exerciseCount,
    supersetCount,
    warmupExerciseCount,
  ];
}

abstract final class WorkoutDaySummaryFormatter {
  static String format(WorkoutDaySummary summary) {
    if (summary.isEmpty) return 'No exercises yet · Tap to add';
    final parts = <String>[];
    parts.add(_pluralise(summary.exerciseCount, 'exercise', 'exercises'));
    if (summary.supersetCount > 0) {
      parts.add(_pluralise(summary.supersetCount, 'superset', 'supersets'));
    }
    if (summary.warmupExerciseCount > 0) {
      parts.add(_pluralise(summary.warmupExerciseCount, 'warmup', 'warmups'));
    }
    return parts.join(' · ');
  }

  static String deletionCost(WorkoutDaySummary summary) {
    final parts = <String>[
      _pluralise(summary.exerciseCount, 'exercise', 'exercises'),
    ];
    if (summary.supersetCount > 0) {
      parts.add(_pluralise(summary.supersetCount, 'superset', 'supersets'));
    }
    if (summary.warmupExerciseCount > 0) {
      parts.add(_pluralise(summary.warmupExerciseCount, 'warmup', 'warmups'));
    }
    return _joinWithAnd(parts);
  }

  static String _pluralise(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _joinWithAnd(List<String> parts) {
    if (parts.length == 1) return parts.first;
    if (parts.length == 2) return '${parts[0]} and ${parts[1]}';
    return '${parts.take(parts.length - 1).join(', ')}, and ${parts.last}';
  }
}
