import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';

part 'superset_group_view_model.freezed.dart';

@freezed
abstract class SupersetGroupViewModel with _$SupersetGroupViewModel {
  const factory SupersetGroupViewModel({
    required String? supersetTag,
    required List<ExerciseViewModel> exercises,
  }) = _SupersetGroupViewModel;
}
