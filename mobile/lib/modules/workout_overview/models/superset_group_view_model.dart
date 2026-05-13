import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';

part 'superset_group_view_model.freezed.dart';

/// A top-level row in the overview list: either one standalone exercise or
/// a contiguous superset of two-or-more exercises sharing a tag.
@Freezed(unionKey: 'type')
sealed class SupersetGroupViewModel with _$SupersetGroupViewModel {
  const factory SupersetGroupViewModel.single({
    required ExerciseViewModel exercise,
  }) = SingleGroupViewModel;

  const factory SupersetGroupViewModel.superset({
    required String tag,
    required List<ExerciseViewModel> exercises,
  }) = SupersetGroup;
}

extension SupersetGroupViewModelExercisesX on SupersetGroupViewModel {
  /// Flat list of exercises in this group (always non-empty, length 1 for
  /// single, ≥2 for superset).
  List<ExerciseViewModel> get allExercises => switch (this) {
    SingleGroupViewModel(:final exercise) => [exercise],
    SupersetGroup(:final exercises) => exercises,
  };
}
