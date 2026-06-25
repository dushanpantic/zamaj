import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class ExerciseEditorEvent extends Equatable {
  const ExerciseEditorEvent();
}

final class ExerciseEditorOpened extends ExerciseEditorEvent {
  const ExerciseEditorOpened({required this.exerciseId});

  final String exerciseId;

  @override
  List<Object?> get props => [exerciseId];
}

final class ExerciseNameChanged extends ExerciseEditorEvent {
  const ExerciseNameChanged({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ExerciseMeasurementTypeChanged extends ExerciseEditorEvent {
  const ExerciseMeasurementTypeChanged({required this.next});

  final MeasurementType next;

  @override
  List<Object?> get props => [next];
}

final class ExerciseNotesChanged extends ExerciseEditorEvent {
  const ExerciseNotesChanged({required this.notes});

  final String? notes;

  @override
  List<Object?> get props => [notes];
}

final class ExerciseVideoUrlChanged extends ExerciseEditorEvent {
  const ExerciseVideoUrlChanged({required this.videoUrl});

  final String? videoUrl;

  @override
  List<Object?> get props => [videoUrl];
}

final class ExerciseVideoUrlActivated extends ExerciseEditorEvent {
  const ExerciseVideoUrlActivated();

  @override
  List<Object?> get props => [];
}

final class ExercisePlannedRestChanged extends ExerciseEditorEvent {
  const ExercisePlannedRestChanged({required this.rawInput});

  final String rawInput;

  @override
  List<Object?> get props => [rawInput];
}

final class PlannedSetAdded extends ExerciseEditorEvent {
  const PlannedSetAdded();

  @override
  List<Object?> get props => [];
}

final class PlannedSetDeleted extends ExerciseEditorEvent {
  const PlannedSetDeleted({required this.setDraftId});

  final String setDraftId;

  @override
  List<Object?> get props => [setDraftId];
}

final class PlannedSetReordered extends ExerciseEditorEvent {
  const PlannedSetReordered({required this.orderedSetDraftIds});

  final List<String> orderedSetDraftIds;

  @override
  List<Object?> get props => [orderedSetDraftIds];
}

final class PlannedSetWeightChanged extends ExerciseEditorEvent {
  const PlannedSetWeightChanged({
    required this.setDraftId,
    required this.rawInput,
  });

  final String setDraftId;
  final String rawInput;

  @override
  List<Object?> get props => [setDraftId, rawInput];
}

final class PlannedSetRepsChanged extends ExerciseEditorEvent {
  const PlannedSetRepsChanged({
    required this.setDraftId,
    required this.rawInput,
  });

  final String setDraftId;
  final String rawInput;

  @override
  List<Object?> get props => [setDraftId, rawInput];
}

final class PlannedSetDurationChanged extends ExerciseEditorEvent {
  const PlannedSetDurationChanged({
    required this.setDraftId,
    required this.rawInput,
  });

  final String setDraftId;
  final String rawInput;

  @override
  List<Object?> get props => [setDraftId, rawInput];
}

/// Sets the weight input on **every** set at once (uniform editing). Sets whose
/// measurement shape has no weight field are left untouched.
final class AllSetsWeightChanged extends ExerciseEditorEvent {
  const AllSetsWeightChanged({required this.rawInput});

  final String rawInput;

  @override
  List<Object?> get props => [rawInput];
}

/// Sets the reps input on **every** set at once. Sets whose measurement shape
/// has no reps field are left untouched.
final class AllSetsRepsChanged extends ExerciseEditorEvent {
  const AllSetsRepsChanged({required this.rawInput});

  final String rawInput;

  @override
  List<Object?> get props => [rawInput];
}

/// Sets the duration input on **every** set at once. Sets whose measurement
/// shape has no duration field are left untouched.
final class AllSetsDurationChanged extends ExerciseEditorEvent {
  const AllSetsDurationChanged({required this.rawInput});

  final String rawInput;

  @override
  List<Object?> get props => [rawInput];
}

/// Sets the number of planned sets to [count] (clamped 1–20). Growing appends
/// sets that inherit the current uniform (last) value; shrinking drops sets from
/// the end.
final class PlannedSetCountChanged extends ExerciseEditorEvent {
  const PlannedSetCountChanged({required this.count});

  final int count;

  @override
  List<Object?> get props => [count];
}

/// Collapses varied sets back to uniform by setting every set to the first
/// set's values. No-op in effect when already uniform or there is one set.
final class AllSetsFlattenedToFirst extends ExerciseEditorEvent {
  const AllSetsFlattenedToFirst();

  @override
  List<Object?> get props => [];
}

/// Bumps the weight on **every** set by [delta] kg (half-kg snapped, clamped
/// ≥0). Sets with no weight field, or a blank/non-numeric weight, are untouched.
final class AllSetsWeightBumped extends ExerciseEditorEvent {
  const AllSetsWeightBumped({required this.delta});

  final double delta;

  @override
  List<Object?> get props => [delta];
}

/// Bumps the reps on **every** set by [delta], preserving range shape (`6-8` →
/// `7-9`) and clamping at zero. Blank/non-numeric reps are untouched.
final class AllSetsRepsBumped extends ExerciseEditorEvent {
  const AllSetsRepsBumped({required this.delta});

  final int delta;

  @override
  List<Object?> get props => [delta];
}

/// Bumps the duration (seconds) on **every** set by [delta], clamped ≥0.
final class AllSetsDurationBumped extends ExerciseEditorEvent {
  const AllSetsDurationBumped({required this.delta});

  final int delta;

  @override
  List<Object?> get props => [delta];
}

final class ExerciseSavePressed extends ExerciseEditorEvent {
  const ExerciseSavePressed();

  @override
  List<Object?> get props => [];
}

/// Links the exercise to a library entry. When [overwriteNameAndVideo] is true
/// the draft's `name` and `metadata.videoUrl` are replaced with the library
/// entry's values. `metadata.notes` is never touched (day-specific).
final class ExerciseLibraryLinked extends ExerciseEditorEvent {
  const ExerciseLibraryLinked({
    required this.libraryExerciseId,
    required this.libraryName,
    required this.libraryVideoUrl,
    required this.overwriteNameAndVideo,
  });

  final String libraryExerciseId;
  final String libraryName;
  final String? libraryVideoUrl;
  final bool overwriteNameAndVideo;

  @override
  List<Object?> get props => [
    libraryExerciseId,
    libraryName,
    libraryVideoUrl,
    overwriteNameAndVideo,
  ];
}

final class ExerciseLibraryUnlinked extends ExerciseEditorEvent {
  const ExerciseLibraryUnlinked();

  @override
  List<Object?> get props => [];
}

/// Applies a recent-history [entry]'s logged (actual) sets to the planned
/// draft, replacing the current planned sets with the session's logged
/// structure (one planned set per logged set, fixed targets).
///
/// A no-op when the entry logged nothing, or when its logged sets are a
/// different measurement type than the exercise (the whole apply is rejected,
/// never partially applied). When the draft already holds user-entered set
/// data the apply is stashed pending a confirmation rather than replacing
/// immediately (see [RecentHistoryApplyConfirmed] / [RecentHistoryApplyDismissed]).
final class RecentHistoryEntryApplied extends ExerciseEditorEvent {
  const RecentHistoryEntryApplied({required this.entry});

  final CapHistoryEntry entry;

  @override
  List<Object?> get props => [entry];
}

/// Confirms the overwrite stashed in `pendingHistoryApply`, replacing the
/// planned sets and clearing the pending state. No payload — the entry already
/// lives in the editing state.
final class RecentHistoryApplyConfirmed extends ExerciseEditorEvent {
  const RecentHistoryApplyConfirmed();

  @override
  List<Object?> get props => [];
}

/// Dismisses the pending overwrite, clearing it and leaving the planned sets
/// untouched.
final class RecentHistoryApplyDismissed extends ExerciseEditorEvent {
  const RecentHistoryApplyDismissed();

  @override
  List<Object?> get props => [];
}
