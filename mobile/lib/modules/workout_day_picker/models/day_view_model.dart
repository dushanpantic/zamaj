import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';

part 'day_view_model.freezed.dart';

@Freezed(unionKey: 'type')
sealed class DayTileStatus with _$DayTileStatus {
  const factory DayTileStatus.loading() = DayTileLoading;

  const factory DayTileStatus.loaded(DayHistorySummary summary) =
      DayTileLoaded;

  const factory DayTileStatus.failure(DomainError error) = DayTileFailure;
}

@freezed
abstract class DayViewModel with _$DayViewModel {
  const factory DayViewModel({
    required WorkoutDay workoutDay,
    required DayTileStatus status,
  }) = _DayViewModel;
}
