import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';

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

final class WorkoutOverviewRefreshed extends WorkoutOverviewEvent {
  const WorkoutOverviewRefreshed();
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

final class WorkoutOverviewExerciseReplaced extends WorkoutOverviewEvent {
  const WorkoutOverviewExerciseReplaced({
    required this.sessionExerciseId,
    required this.substituteName,
    required this.substituteMeasurementType,
    this.substituteMetadata,
  });

  final String sessionExerciseId;
  final String substituteName;
  final MeasurementType substituteMeasurementType;
  final ExerciseMetadata? substituteMetadata;

  @override
  List<Object?> get props => [
    sessionExerciseId,
    substituteName,
    substituteMeasurementType,
    substituteMetadata,
  ];
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
