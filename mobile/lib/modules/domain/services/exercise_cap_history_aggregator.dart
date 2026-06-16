import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/cap_history.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/session_history.dart';

/// Pure-Dart derivations behind the progression hints: whether a logged session
/// "capped" its planned prescription, plus (later steps) the recent set-history
/// table and the needs-attention badge.
///
/// A session caps a movement iff **every** planned working set was executed and
/// each met (or exceeded) its own ceiling — the top of a rep target or a
/// time-based hold's planned seconds. Vary-by-set plans are judged per set
/// against each set's own ceiling; there is no special-casing.
abstract final class ExerciseCapHistoryAggregator {
  /// Whether [actualSets] caps the [plannedSets] prescription.
  ///
  /// Capped iff at least every planned working set was executed (`actualSets`
  /// has an entry for each planned index) and each of those sets met its own
  /// ceiling. Extra logged sets beyond the plan do not affect the result.
  static bool isCapped({
    required List<PlannedSetValues> plannedSets,
    required List<ActualSetValues> actualSets,
  }) {
    if (plannedSets.isEmpty) return false;
    if (actualSets.length < plannedSets.length) return false;
    for (var i = 0; i < plannedSets.length; i++) {
      if (!_setMeetsCeiling(plannedSets[i], actualSets[i])) return false;
    }
    return true;
  }

  /// The movement's recent set-history: the [limit] most recent ended sessions
  /// that logged [libraryExerciseId], newest first, aggregated across every
  /// program the movement appears in.
  ///
  /// Attribution mirrors [ExerciseProgressAggregator]: a session contributes
  /// one entry, sourced from the snapshot's *planned* exercise linked to
  /// [libraryExerciseId]. When the movement appears more than once in a day the
  /// first linked instance is used. Recomputed live, so a deleted session simply
  /// stops appearing.
  static CapHistory computeHistory({
    required String libraryExerciseId,
    required List<Session> sessions,
    int limit = 5,
  }) {
    final entries = <CapHistoryEntry>[];
    for (final session in SessionHistory.completedNewestFirst(sessions)) {
      final entry = _entryFor(session, libraryExerciseId);
      if (entry == null) continue;
      entries.add(entry);
      if (entries.length == limit) break;
    }
    return CapHistory(entries: entries);
  }

  /// One [CapHistoryEntry] for [session] sourced from the first snapshot
  /// exercise linked to [libraryExerciseId], or null when the session logged
  /// none for it.
  static CapHistoryEntry? _entryFor(Session session, String libraryExerciseId) {
    final plannedById = <String, Exercise>{
      for (final group in session.snapshot.workoutDay.exerciseGroups)
        for (final exercise in group.exercises) exercise.id: exercise,
    };

    for (final sessionExercise in session.sessionExercises) {
      final planned = plannedById[sessionExercise.plannedExerciseIdInSnapshot];
      if (planned == null) continue;
      if (planned.libraryExerciseId != libraryExerciseId) continue;

      final plannedSets = _plannedValuesOf(planned.sets);
      final actualSets = _actualValuesOf(sessionExercise);
      return CapHistoryEntry(
        date: session.startedAt,
        programId: session.snapshot.workoutDay.programId,
        sourceWorkoutDayName: session.snapshot.workoutDay.name,
        plannedSets: plannedSets,
        actualSets: actualSets,
        isCapped: isCapped(plannedSets: plannedSets, actualSets: actualSets),
      );
    }
    return null;
  }

  /// The position-ordered planned values of [sets].
  static List<PlannedSetValues> _plannedValuesOf(List<WorkoutSet> sets) {
    final ordered = [...sets]..sort((a, b) => a.position.compareTo(b.position));
    return [for (final set in ordered) set.plannedValues];
  }

  /// The position-ordered logged values of [sessionExercise].
  static List<ActualSetValues> _actualValuesOf(
    SessionExercise sessionExercise,
  ) {
    final ordered = [...sessionExercise.executedSets]
      ..sort((a, b) => a.position.compareTo(b.position));
    return [for (final set in ordered) set.actualValues];
  }

  /// Whether a single [actual] set meets the ceiling of its [planned] set.
  static bool _setMeetsCeiling(
    PlannedSetValues planned,
    ActualSetValues actual,
  ) {
    final ceiling = _ceilingFor(planned);
    return switch ((planned, actual)) {
      (PlannedRepBased(), ActualRepBased(:final reps)) => reps >= ceiling,
      (PlannedBodyweight(), ActualBodyweight(:final reps)) => reps >= ceiling,
      (PlannedTimeBased(), ActualTimeBased(:final durationSeconds)) =>
        durationSeconds >= ceiling,
      _ => false,
    };
  }
}

/// The per-set ceiling [planned] is judged against: the top of a rep target
/// (fixed reps or a range's `maxReps`) for rep-based and bodyweight sets, or
/// the planned hold for a time-based set.
int _ceilingFor(PlannedSetValues planned) => switch (planned) {
  PlannedRepBased(:final repTarget) => _repCeiling(repTarget),
  PlannedBodyweight(:final repTarget) => _repCeiling(repTarget),
  PlannedTimeBased(:final durationSeconds) => durationSeconds,
};

/// The top of a [RepTarget]: a fixed target's reps or a range's `maxReps`.
int _repCeiling(RepTarget target) => switch (target) {
  RepTargetFixed(:final reps) => reps,
  RepTargetRange(:final maxReps) => maxReps,
};
