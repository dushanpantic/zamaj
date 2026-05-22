import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class ExerciseLibraryEditorEvent extends Equatable {
  const ExerciseLibraryEditorEvent();
}

final class ExerciseLibraryEditorOpened extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorOpened({this.libraryExerciseId});

  /// `null` triggers create mode.
  final String? libraryExerciseId;

  @override
  List<Object?> get props => [libraryExerciseId];
}

final class ExerciseLibraryEditorNameChanged
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorNameChanged({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ExerciseLibraryEditorMeasurementTypeChanged
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorMeasurementTypeChanged({required this.next});

  final MeasurementType next;

  @override
  List<Object?> get props => [next];
}

final class ExerciseLibraryEditorVideoUrlChanged
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorVideoUrlChanged({required this.videoUrl});

  final String videoUrl;

  @override
  List<Object?> get props => [videoUrl];
}

final class ExerciseLibraryEditorCuesChanged
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorCuesChanged({required this.cues});

  final String cues;

  @override
  List<Object?> get props => [cues];
}

final class ExerciseLibraryEditorSavePressed
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorSavePressed();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryEditorArchivePressed
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorArchivePressed();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryEditorUnarchivePressed
    extends ExerciseLibraryEditorEvent {
  const ExerciseLibraryEditorUnarchivePressed();

  @override
  List<Object?> get props => [];
}
