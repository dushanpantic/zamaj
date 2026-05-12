import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_overview_args.freezed.dart';

@freezed
abstract class WorkoutOverviewArgs with _$WorkoutOverviewArgs {
  const factory WorkoutOverviewArgs({required String sessionId}) =
      _WorkoutOverviewArgs;
}
