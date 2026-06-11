import 'package:equatable/equatable.dart';

/// Marker for the most-recently-completed set in this focus session.
///
/// Surfaces in [FocusModeReady.undoable] as a persistent row in the focus
/// bottom bar carrying an Undo action. The row is not a transient SnackBar:
/// it stays put until the next mutation lands, the active group switches, or
/// Undo is pressed.
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
