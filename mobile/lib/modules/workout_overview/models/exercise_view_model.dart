import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';

part 'exercise_view_model.freezed.dart';

/// Display-ready projection of a single [SessionExercise], with its planned
/// metadata pre-resolved against the immutable session snapshot.
///
/// The view model intentionally lifts the planned name, summary, metadata,
/// and measurement type into top-level fields so the widget tree never
/// re-walks the snapshot. The original [Exercise] is not stored to keep the
/// "session exercise ↔ planned exercise" linkage single-sourced; widgets
/// that need both should look the planned exercise up via the assembler's
/// index.
@freezed
abstract class ExerciseViewModel with _$ExerciseViewModel {
  const factory ExerciseViewModel({
    required SessionExercise sessionExercise,
    required String plannedExerciseName,
    required String plannedSummary,
    required MeasurementType plannedMeasurementType,
    required ExerciseMetadata plannedMetadata,
    required int? plannedRestSeconds,
    required List<SetRowViewModel> setRows,
    required bool isCursorTarget,
    required int? cursorSetIndex,
    required MeasurementType effectiveMeasurementType,
  }) = _ExerciseViewModel;
}
