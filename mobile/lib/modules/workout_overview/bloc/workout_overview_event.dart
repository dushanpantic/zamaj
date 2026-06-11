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

final class WorkoutOverviewExerciseSkipped extends WorkoutOverviewEvent {
  const WorkoutOverviewExerciseSkipped(this.sessionExerciseId);

  final String sessionExerciseId;

  @override
  List<Object?> get props => [sessionExerciseId];
}

final class WorkoutOverviewExerciseMarkedDone extends WorkoutOverviewEvent {
  const WorkoutOverviewExerciseMarkedDone(this.sessionExerciseId);

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
