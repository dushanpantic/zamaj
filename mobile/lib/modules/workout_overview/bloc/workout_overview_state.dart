import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

sealed class WorkoutOverviewState extends Equatable {
  const WorkoutOverviewState();

  @override
  List<Object?> get props => const [];
}

final class WorkoutOverviewInitial extends WorkoutOverviewState {
  const WorkoutOverviewInitial();
}

final class WorkoutOverviewLoading extends WorkoutOverviewState {
  const WorkoutOverviewLoading(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class WorkoutOverviewNotFound extends WorkoutOverviewState {
  const WorkoutOverviewNotFound(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class WorkoutOverviewLoadFailure extends WorkoutOverviewState {
  const WorkoutOverviewLoadFailure({
    required this.sessionId,
    required this.error,
  });

  final String sessionId;
  final DomainError error;

  @override
  List<Object?> get props => [sessionId, error];
}

final class WorkoutOverviewLoaded extends WorkoutOverviewState {
  const WorkoutOverviewLoaded({
    required this.sessionState,
    required this.groups,
    required this.expandedExerciseIds,
    this.mutationInFlight = false,
    this.lastTransientError,
  });

  /// Authoritative snapshot of the session from the engine. Every other
  /// field is derived from this or is pure UI state.
  final SessionState sessionState;

  /// Display tree assembled from [sessionState] by the assembler. Stored to
  /// avoid re-running the assembler on every widget rebuild.
  final List<SupersetGroupViewModel> groups;

  /// Pure UI state: which exercise cards are currently expanded.
  ///
  /// Auto-managed by the bloc: opening a session always expands the cursor
  /// target so the user lands on the next set to log; everything else
  /// starts collapsed.
  final Set<String> expandedExerciseIds;

  /// True while a mutation request is awaiting the engine. Used by the UI
  /// to disable inputs that would race with the in-flight write.
  final bool mutationInFlight;

  /// Most recent mutation failure surfaced as a dismissible banner. Cleared
  /// when the user dismisses it or another mutation succeeds.
  final DomainError? lastTransientError;

  bool get isEnded => sessionState.session.endedAt != null;

  WorkoutOverviewLoaded copyWith({
    SessionState? sessionState,
    List<SupersetGroupViewModel>? groups,
    Set<String>? expandedExerciseIds,
    bool? mutationInFlight,
    DomainError? Function()? lastTransientError,
  }) {
    return WorkoutOverviewLoaded(
      sessionState: sessionState ?? this.sessionState,
      groups: groups ?? this.groups,
      expandedExerciseIds: expandedExerciseIds ?? this.expandedExerciseIds,
      mutationInFlight: mutationInFlight ?? this.mutationInFlight,
      lastTransientError: lastTransientError != null
          ? lastTransientError()
          : this.lastTransientError,
    );
  }

  @override
  List<Object?> get props => [
    sessionState,
    groups,
    expandedExerciseIds,
    mutationInFlight,
    lastTransientError,
  ];
}
