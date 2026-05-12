import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_day_picker_args.freezed.dart';

@freezed
abstract class WorkoutDayPickerArgs with _$WorkoutDayPickerArgs {
  const factory WorkoutDayPickerArgs({required String programId}) =
      _WorkoutDayPickerArgs;
}
