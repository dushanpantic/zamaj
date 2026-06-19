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

    /// The snapshot exercise's Library link, or null when it was never linked.
    /// Carried so review surfaces can open the cross-session progress view for
    /// the right Library entry (and show the "unlinked" state when null).
    required String? libraryExerciseId,
    required MeasurementType plannedMeasurementType,
    required ExerciseMetadata plannedMetadata,
    required int? plannedRestSeconds,
    required List<SetRowViewModel> setRows,

    /// True when this exercise has at least one row in [setRows] flagged as
    /// `isLoggable` — i.e. the user can log a new set on it right now.
    /// Derived from the engine's [SessionState.openTargets] projection.
    required bool isLoggable,
    required MeasurementType effectiveMeasurementType,
    @Default(ExerciseGroupRole.main) ExerciseGroupRole plannedGroupRole,

    /// True when the user may log an extra set beyond the planned quota on this
    /// exercise: it is `completed` and the session is still live. The kebab's
    /// "Add set" item is gated on this — the re-do affordance for a completed
    /// exercise (skipped/ended use Resume; unfinished use the inline LOG SET).
    @Default(false) bool canAddSet,
  }) = _ExerciseViewModel;
}

extension ExerciseViewModelDisplayNameX on ExerciseViewModel {
  /// The name to show for this exercise: a replaced exercise shows its
  /// substitute's name, everything else shows the planned name.
  String get displayName => switch (sessionExercise.state) {
    ReplacedState(:final substitute) => substitute.name,
    _ => plannedExerciseName,
  };
}
