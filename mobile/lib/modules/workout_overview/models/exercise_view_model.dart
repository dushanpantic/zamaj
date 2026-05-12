import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';

part 'exercise_view_model.freezed.dart';

@freezed
abstract class ExerciseViewModel with _$ExerciseViewModel {
  const factory ExerciseViewModel({
    required SessionExercise sessionExercise,
    required Exercise plannedExerciseInSnapshot,
    required String plannedSummary,
    required List<SetRowViewModel> setRows,
    required bool isCursorTarget,
    required int? cursorSetIndex,
    required MeasurementType effectiveMeasurementType,
  }) = _ExerciseViewModel;
}
