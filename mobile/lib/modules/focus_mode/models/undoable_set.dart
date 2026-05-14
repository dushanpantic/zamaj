import 'package:equatable/equatable.dart';

/// Marker for the most-recently-completed set in this focus session.
///
/// Surfaces in [FocusModeReady.undoable] for one transient window so the
/// UI can render a SnackBar with an Undo action. Cleared after the snackbar
/// dismisses, after another mutation lands, or after Undo is pressed.
class UndoableSet extends Equatable {
  const UndoableSet({
    required this.executedSetId,
    required this.sessionExerciseId,
    required this.exerciseDisplayName,
  });

  final String executedSetId;
  final String sessionExerciseId;
  final String exerciseDisplayName;

  @override
  List<Object?> get props => [
    executedSetId,
    sessionExerciseId,
    exerciseDisplayName,
  ];
}
