// TEMP: snapshot link repair — remove after one-time run
//
// Pure-Dart planner for the one-shot history-link repair. Given a program's
// current [WorkoutDay] templates and its already-hydrated ended [Session]s, it
// computes which session snapshots need their exercises' [libraryExerciseId]
// rewritten to the value the current template now carries, plus a structured
// report of what could and could not be matched. No I/O — every input is
// already hydrated and every output is a plain value, so the whole thing is
// unit-testable and trivial to delete.

import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';

/// A single session whose snapshot day should be overwritten with [workoutDay].
// TEMP: snapshot link repair — remove after one-time run
class SnapshotLinkRewrite {
  const SnapshotLinkRewrite({
    required this.sessionId,
    required this.workoutDay,
  });

  final String sessionId;
  final WorkoutDay workoutDay;
}

/// The computed repair plan: the per-session rewrites plus report counts.
// TEMP: snapshot link repair — remove after one-time run
class SnapshotLinkBackfillPlan {
  const SnapshotLinkBackfillPlan({
    required this.rewrites,
    required this.sessionsScanned,
    required this.exercisesReLinked,
    required this.unmatched,
    required this.currentUnlinked,
    required this.dayMissing,
  });

  /// Sessions whose snapshot changed; empty when nothing needs rewriting.
  final List<SnapshotLinkRewrite> rewrites;

  /// Total ended sessions considered.
  final int sessionsScanned;

  /// Snapshot exercises whose link will be rewritten to the current value.
  final int exercisesReLinked;

  /// Snapshot exercises with no usable match (id gone, name absent/ambiguous).
  final int unmatched;

  /// Snapshot exercises whose matched current exercise is itself unlinked, so
  /// the existing link is preserved rather than cleared.
  final int currentUnlinked;

  /// Sessions whose workout day no longer exists in the current templates.
  final int dayMissing;

  /// Sessions that will actually be rewritten.
  int get sessionsChanged => rewrites.length;
}

// TEMP: snapshot link repair — remove after one-time run
abstract final class SnapshotLinkBackfill {
  /// Computes the repair plan for [sessions] against [currentDays].
  ///
  /// Matching is scoped to the day identified by `session.workoutDayId`:
  /// by exercise id first, then by an unambiguous normalized-name match within
  /// that day. A link is never overwritten with `null`. A session is rewritten
  /// only when at least one of its exercises changes.
  static SnapshotLinkBackfillPlan plan({
    required List<WorkoutDay> currentDays,
    required List<Session> sessions,
  }) {
    final dayById = {for (final day in currentDays) day.id: day};

    final rewrites = <SnapshotLinkRewrite>[];
    var exercisesReLinked = 0;
    var unmatched = 0;
    var currentUnlinked = 0;
    var dayMissing = 0;

    for (final session in sessions) {
      final currentDay = dayById[session.workoutDayId];
      if (currentDay == null) {
        dayMissing++;
        continue;
      }

      final currentById = <String, Exercise>{
        for (final group in currentDay.exerciseGroups)
          for (final exercise in group.exercises) exercise.id: exercise,
      };
      final currentByName = <String, List<Exercise>>{};
      for (final group in currentDay.exerciseGroups) {
        for (final exercise in group.exercises) {
          final normalized = _normalize(exercise.name);
          if (normalized.isEmpty) continue;
          (currentByName[normalized] ??= []).add(exercise);
        }
      }

      var dayChanged = false;
      final newGroups = <ExerciseGroup>[];
      for (final group in session.snapshot.workoutDay.exerciseGroups) {
        final newExercises = <Exercise>[];
        for (final exercise in group.exercises) {
          final outcome = _decide(exercise, currentById, currentByName);
          switch (outcome.kind) {
            case _Kind.relink:
              newExercises.add(
                exercise.copyWith(libraryExerciseId: outcome.libraryId),
              );
              exercisesReLinked++;
              dayChanged = true;
            case _Kind.unmatched:
              unmatched++;
              newExercises.add(exercise);
            case _Kind.currentUnlinked:
              currentUnlinked++;
              newExercises.add(exercise);
            case _Kind.unchanged:
              newExercises.add(exercise);
          }
        }
        newGroups.add(group.copyWith(exercises: newExercises));
      }

      if (dayChanged) {
        rewrites.add(
          SnapshotLinkRewrite(
            sessionId: session.id,
            workoutDay: session.snapshot.workoutDay.copyWith(
              exerciseGroups: newGroups,
            ),
          ),
        );
      }
    }

    return SnapshotLinkBackfillPlan(
      rewrites: rewrites,
      sessionsScanned: sessions.length,
      exercisesReLinked: exercisesReLinked,
      unmatched: unmatched,
      currentUnlinked: currentUnlinked,
      dayMissing: dayMissing,
    );
  }

  /// The per-exercise decision: match the snapshot [exercise] to a current
  /// exercise (by id, then by unique normalized name) and decide whether to
  /// re-link, preserve, or report.
  static _Outcome _decide(
    Exercise exercise,
    Map<String, Exercise> currentById,
    Map<String, List<Exercise>> currentByName,
  ) {
    var match = currentById[exercise.id];
    if (match == null) {
      final candidates = currentByName[_normalize(exercise.name)];
      if (candidates == null || candidates.length != 1) {
        return const _Outcome(_Kind.unmatched);
      }
      match = candidates.single;
    }

    final currentLink = match.libraryExerciseId;
    if (currentLink == null) return const _Outcome(_Kind.currentUnlinked);
    if (currentLink == exercise.libraryExerciseId) {
      return const _Outcome(_Kind.unchanged);
    }
    return _Outcome(_Kind.relink, currentLink);
  }

  /// The same normalization the link-suggester uses, for consistency.
  static String _normalize(String name) => name.trim().toLowerCase();
}

enum _Kind { relink, unmatched, currentUnlinked, unchanged }

class _Outcome {
  const _Outcome(this.kind, [this.libraryId]);

  final _Kind kind;
  final String? libraryId;
}
