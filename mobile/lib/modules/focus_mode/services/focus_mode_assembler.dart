import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';

/// Builds the focus-mode view model from a [SessionState].
///
/// Returns null when the cursor is completed — the bloc transitions to a
/// dedicated workout-complete state in that case so the assembler stays
/// pure (no synthetic view models).
abstract final class FocusModeAssembler {
  static FocusModeViewModel? assemble(SessionState state) {
    final cursor = state.cursor;
    if (cursor is! ActiveCursor) return null;

    final session = state.session;
    final exercise = session.sessionExercises.firstWhere(
      (e) => e.id == cursor.sessionExerciseId,
      orElse: () => throw NotFoundError(
        entityType: 'SessionExercise',
        id: cursor.sessionExerciseId,
      ),
    );

    final planned = _lookupPlanned(sessionExercise: exercise, session: session);

    final effectiveMt = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.measurementType,
      _ => planned.measurementType,
    };
    final isReplaced = exercise.state is ReplacedState;
    final displayName = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.name,
      _ => planned.name,
    };
    final displayMetadata = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.metadata,
      _ => planned.metadata,
    };

    final sortedPlanned = List<WorkoutSet>.of(planned.sets)
      ..sort((a, b) => a.position.compareTo(b.position));

    final currentPlanned = cursor.setIndex < sortedPlanned.length
        ? sortedPlanned[cursor.setIndex]
        : null;

    final sortedExecuted = List<ExecutedSet>.of(exercise.executedSets)
      ..sort((a, b) => a.position.compareTo(b.position));
    final lastExecuted = sortedExecuted.isEmpty ? null : sortedExecuted.last;

    final upNext = _computeUpNextName(
      session: session,
      currentExerciseId: exercise.id,
    );

    return FocusModeViewModel(
      sessionId: session.id,
      workoutDayName: session.snapshot.workoutDay.name,
      sessionExerciseId: exercise.id,
      displayExerciseName: displayName,
      displayMetadata: displayMetadata,
      effectiveMeasurementType: effectiveMt,
      currentSetIndex: cursor.setIndex,
      totalPlannedSets: sortedPlanned.length,
      completedSetsCount: sortedExecuted.length,
      currentPlannedValues: currentPlanned?.plannedValues,
      plannedSummary: _summarizePlanned(planned),
      currentPlannedSetIdInSnapshot: currentPlanned?.id,
      lastExecutedValues: lastExecuted?.actualValues,
      upNextExerciseName: upNext,
      plannedRestSeconds: planned.plannedRestSeconds,
      isReplaced: isReplaced,
      plannedExerciseName: planned.name,
    );
  }

  static Exercise _lookupPlanned({
    required SessionExercise sessionExercise,
    required Session session,
  }) {
    for (final group in session.snapshot.workoutDay.exerciseGroups) {
      for (final ex in group.exercises) {
        if (ex.id == sessionExercise.plannedExerciseIdInSnapshot) {
          return ex;
        }
      }
    }
    throw NotFoundError(
      entityType: 'Exercise',
      id: sessionExercise.plannedExerciseIdInSnapshot,
    );
  }

  /// Finds the next actionable exercise after [currentExerciseId] in
  /// position order. Skipped/completed exercises are passed over; the
  /// preview is meant to answer "what am I doing next?", not show the
  /// whole workout.
  static String? _computeUpNextName({
    required Session session,
    required String currentExerciseId,
  }) {
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final currentIndex = sorted.indexWhere((e) => e.id == currentExerciseId);
    if (currentIndex == -1) return null;

    for (var i = currentIndex + 1; i < sorted.length; i++) {
      final next = sorted[i];
      if (next.state is SkippedState) continue;
      if (next.state is CompletedState) {
        final planned = _lookupPlanned(sessionExercise: next, session: session);
        if (next.executedSets.length >= planned.sets.length) continue;
      }
      return switch (next.state) {
        ReplacedState(:final substitute) => substitute.name,
        _ => _lookupPlanned(sessionExercise: next, session: session).name,
      };
    }
    return null;
  }

  static String _summarizePlanned(Exercise plannedExercise) {
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
