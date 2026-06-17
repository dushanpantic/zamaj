import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_progress_series.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/progress_point.dart';
import 'package:zamaj/modules/domain/models/session.dart';

/// Pure-Dart aggregator that derives an exercise's [ExerciseProgressSeries] —
/// the top set logged per completed session, across every program the exercise
/// has appeared in — from already-hydrated [Session]s.
///
/// "Top set" is a session's heaviest `repBased` set (max `weightKg`, ties broken
/// by higher `reps`). Only ended sessions count, and only `repBased` exercises
/// linked to the target `libraryExerciseId` contribute. The series is recomputed
/// from live data on every call — there is no precomputed aggregate, so a deleted
/// session simply stops appearing.
///
/// v1 attributes sets by the session snapshot's *planned* exercise
/// (`libraryExerciseId` / `measurementType`); it does not resolve a
/// [ReplacedState] substitute's own link. Replace is a dormant feature, so this
/// has no live effect; reconcile with `EffectiveExercises` if it is reactivated.
abstract final class ExerciseProgressAggregator {
  /// Computes the oldest-first top-set series for [libraryExerciseId] from
  /// [sessions]. Non-ended sessions, sessions that never logged the exercise,
  /// and non-`repBased` linkings contribute nothing.
  static ExerciseProgressSeries compute({
    required String libraryExerciseId,
    required List<Session> sessions,
  }) {
    // Only ended sessions count — the same "completed = endedAt set" rule the
    // SessionHistory derivations use. Ordered oldest-first, ties on startedAt
    // broken by id so the series is deterministic regardless of input order
    // (mirrors SessionHistory.completedNewestFirst).
    final completed =
        [
          for (final s in sessions)
            if (s.endedAt != null) s,
        ]..sort((a, b) {
          final byDate = a.startedAt.compareTo(b.startedAt);
          return byDate != 0 ? byDate : a.id.compareTo(b.id);
        });

    final points = <ProgressPoint>[];
    for (final session in completed) {
      final topSet = _topSetForExercise(session, libraryExerciseId);
      if (topSet == null) continue;

      points.add(
        ProgressPoint(
          date: session.startedAt,
          topSetWeightKg: topSet.weightKg,
          reps: topSet.reps,
          programId: session.snapshot.workoutDay.programId,
          sourceWorkoutDayName: session.snapshot.workoutDay.name,
        ),
      );
    }

    return ExerciseProgressSeries(points: points);
  }

  /// The heaviest `repBased` set logged for [libraryExerciseId] in [session], or
  /// null when the session logged none for it. Aggregates across every snapshot
  /// exercise linked to that library entry (an exercise may appear more than
  /// once in a day). Ties on weight are broken by the higher rep count.
  static ActualRepBased? _topSetForExercise(
    Session session,
    String libraryExerciseId,
  ) {
    final plannedById = <String, Exercise>{
      for (final group in session.snapshot.workoutDay.exerciseGroups)
        for (final exercise in group.exercises) exercise.id: exercise,
    };

    ActualRepBased? best;
    for (final sessionExercise in session.sessionExercises) {
      final planned = plannedById[sessionExercise.plannedExerciseIdInSnapshot];
      if (planned == null) continue;
      if (planned.libraryExerciseId != libraryExerciseId) continue;
      if (planned.measurementType is! RepBasedMeasurement) continue;

      for (final executedSet in sessionExercise.executedSets) {
        final values = executedSet.actualValues;
        if (values is! ActualRepBased) continue;
        if (best == null || _beats(values, best)) best = values;
      }
    }
    return best;
  }

  /// Whether [candidate] is a heavier top set than [current]: a higher weight,
  /// or an equal weight with more reps.
  static bool _beats(ActualRepBased candidate, ActualRepBased current) {
    if (candidate.weightKg != current.weightKg) {
      return candidate.weightKg > current.weightKg;
    }
    return candidate.reps > current.reps;
  }
}
