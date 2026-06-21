import 'package:zamaj/modules/domain/models/exercise_state.dart';

/// Pure auto-completion state machine for a session exercise as sets are logged
/// or deleted during a live session.
///
/// This is the single definition of the quota-driven transitions the Drift
/// session repository previously computed inline. Auto-completion is
/// deliberately one-directional from [UnfinishedState] and reversion only from
/// [CompletedState]; the explicit terminal [SkippedState] is never moved by set
/// logging.
abstract final class ExerciseStateTransitions {
  /// The state after logging a set. An [UnfinishedState] whose executed-set
  /// count has reached the planned quota auto-completes; every other state is
  /// returned unchanged.
  static ExerciseState afterSetLogged(
    ExerciseState state, {
    required int executedSetCount,
    required int plannedSetCount,
  }) {
    if (state is UnfinishedState && executedSetCount >= plannedSetCount) {
      return const ExerciseState.completed();
    }
    return state;
  }

  /// The state after deleting a set. A [CompletedState] that has dropped below
  /// the planned quota reverts to [UnfinishedState]; every other state is
  /// returned unchanged.
  static ExerciseState afterSetDeleted(
    ExerciseState state, {
    required int executedSetCount,
    required int plannedSetCount,
  }) {
    if (state is CompletedState && executedSetCount < plannedSetCount) {
      return const ExerciseState.unfinished();
    }
    return state;
  }
}
