import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';

// Public events drive UI intents. Events prefixed with `Internal` are
// emitted by the bloc itself in response to its session-state subscription
// — they are part of the bloc's internal protocol but must live here so
// they remain inside the sealed hierarchy.

sealed class WorkoutOverviewEvent extends Equatable {
  const WorkoutOverviewEvent();

  @override
  List<Object?> get props => const [];
}

final class WorkoutOverviewOpened extends WorkoutOverviewEvent {
  const WorkoutOverviewOpened(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class WorkoutOverviewRetried extends WorkoutOverviewEvent {
  const WorkoutOverviewRetried();
}

final class WorkoutOverviewErrorDismissed extends WorkoutOverviewEvent {
  const WorkoutOverviewErrorDismissed();
}

final class WorkoutOverviewExpansionToggled extends WorkoutOverviewEvent {
  const WorkoutOverviewExpansionToggled(this.sessionExerciseId);

  final String sessionExerciseId;

  @override
  List<Object?> get props => [sessionExerciseId];
}

final class WorkoutOverviewSetLogged extends WorkoutOverviewEvent {
  const WorkoutOverviewSetLogged({
    required this.sessionExerciseId,
    required this.actualValues,
    this.plannedSetIdInSnapshot,
  });

  final String sessionExerciseId;
  final ActualSetValues actualValues;
  final String? plannedSetIdInSnapshot;

  @override
  List<Object?> get props => [
    sessionExerciseId,
    actualValues,
    plannedSetIdInSnapshot,
  ];
}

final class WorkoutOverviewSetEdited extends WorkoutOverviewEvent {
  const WorkoutOverviewSetEdited({
    required this.executedSetId,
    required this.actualValues,
  });

  final String executedSetId;
  final ActualSetValues actualValues;

  @override
  List<Object?> get props => [executedSetId, actualValues];
}

/// The single terminal action for a live exercise. Despite the name it now
/// covers both user intents — "Skip exercise" (no sets logged) and "End
/// exercise" (some sets logged) — because both record the exercise as terminal
/// with whatever sets it already has. The name is kept to avoid churn; read
/// surfaces derive the honest outcome (skipped vs partial) from the set counts
/// via `ExerciseOutcomes.of`.
final class WorkoutOverviewExerciseSkipped extends WorkoutOverviewEvent {
  const WorkoutOverviewExerciseSkipped(this.sessionExerciseId);

  final String sessionExerciseId;

  @override
  List<Object?> get props => [sessionExerciseId];
}

/// Resolves a drag-and-drop interaction in the assembled view-model space
/// into a [DropIntent] and dispatches the matching engine mutation.
final class WorkoutOverviewDropResolved extends WorkoutOverviewEvent {
  const WorkoutOverviewDropResolved({
    required this.draggedSessionExerciseId,
    required this.target,
  });

  final String draggedSessionExerciseId;
  final DropTarget target;

  @override
  List<Object?> get props => [draggedSessionExerciseId, target];
}

final class WorkoutOverviewSupersetUngrouped extends WorkoutOverviewEvent {
  const WorkoutOverviewSupersetUngrouped(this.supersetTag);

  final String supersetTag;

  @override
  List<Object?> get props => [supersetTag];
}

/// Reorders a whole superset as one contiguous block — dispatched by the
/// header drag handle (dropped into a between-group gap) and the Move up/down
/// header actions. [targetUnfinishedIndex] is the gap's position in the global
/// unfinished id sequence (the same coordinate [DropTarget.beforeIndex] uses).
/// The bloc routes it through [SupersetReorderResolver] then the existing
/// `reorderUnfinished` path — no new engine mutation.
final class WorkoutOverviewSupersetReordered extends WorkoutOverviewEvent {
  const WorkoutOverviewSupersetReordered({
    required this.supersetTag,
    required this.targetUnfinishedIndex,
  });

  final String supersetTag;
  final int targetUnfinishedIndex;

  @override
  List<Object?> get props => [supersetTag, targetUnfinishedIndex];
}

final class WorkoutOverviewSessionNoteAdded extends WorkoutOverviewEvent {
  const WorkoutOverviewSessionNoteAdded(this.body);

  final String body;

  @override
  List<Object?> get props => [body];
}

final class WorkoutOverviewExtraWorkAdded extends WorkoutOverviewEvent {
  const WorkoutOverviewExtraWorkAdded(this.body);

  final String body;

  @override
  List<Object?> get props => [body];
}

/// Logs one extra set beyond the planned quota on [sessionExerciseId].
///
/// The single secondary "re-do more" affordance for a completed exercise: the
/// bloc seeds the new set from the exercise's last logged set (via
/// `engine.suggestValuesFor`) and routes it through the same `completeSet`
/// path. The exercise stays completed; the new set is recorded as work beyond
/// the plan, never folded into the snapshot.
final class WorkoutOverviewExtraSetRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewExtraSetRequested(this.sessionExerciseId);

  final String sessionExerciseId;

  @override
  List<Object?> get props => [sessionExerciseId];
}

/// Adds an exercise to the live session from a built [AddedExercisePlan]
/// (library-linked or one-off). Routed through `engine.addExercise`; a
/// duplicate-movement guard rejection surfaces as a transient error.
final class WorkoutOverviewAddExerciseRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewAddExerciseRequested(this.plan);

  final AddedExercisePlan plan;

  @override
  List<Object?> get props => [plan];
}

/// Resumes a skipped/ended exercise back to in-progress (the re-do path for a
/// terminated movement), retaining its logged sets. Routed through
/// `engine.resumeExercise`.
final class WorkoutOverviewResumeRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewResumeRequested(this.sessionExerciseId);

  final String sessionExerciseId;

  @override
  List<Object?> get props => [sessionExerciseId];
}

/// Replaces [sessionExerciseId] with a built [AddedExercisePlan]: the original
/// is terminated (skip/end) and a new exercise is added in its place, in one
/// action. Routed through `engine.replaceExercise`; a duplicate-movement guard
/// rejection surfaces as a transient error and leaves the original unchanged.
final class WorkoutOverviewReplaceRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewReplaceRequested({
    required this.sessionExerciseId,
    required this.plan,
  });

  final String sessionExerciseId;
  final AddedExercisePlan plan;

  @override
  List<Object?> get props => [sessionExerciseId, plan];
}

final class WorkoutOverviewSessionEnded extends WorkoutOverviewEvent {
  const WorkoutOverviewSessionEnded();
}

final class InternalSessionPushed extends WorkoutOverviewEvent {
  const InternalSessionPushed(this.sessionState);
  final SessionState sessionState;
  @override
  List<Object?> get props => [sessionState];
}

final class InternalSessionMissing extends WorkoutOverviewEvent {
  const InternalSessionMissing(this.sessionId);
  final String sessionId;
  @override
  List<Object?> get props => [sessionId];
}

final class InternalSessionFailed extends WorkoutOverviewEvent {
  const InternalSessionFailed(this.error, this.sessionId);
  final DomainError error;
  final String sessionId;
  @override
  List<Object?> get props => [error, sessionId];
}
