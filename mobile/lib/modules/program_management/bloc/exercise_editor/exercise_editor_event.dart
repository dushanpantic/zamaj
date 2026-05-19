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

final class ExerciseSavePressed extends ExerciseEditorEvent {
  const ExerciseSavePressed();

  @override
  List<Object?> get props => [];
}
