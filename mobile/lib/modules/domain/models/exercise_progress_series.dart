import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/models/progress_point.dart';

part 'exercise_progress_series.freezed.dart';

/// An exercise's top-set progress over time: a chronologically-ordered
/// (oldest-first) list of [ProgressPoint]s aggregated across every program the
/// exercise has appeared in.
@freezed
abstract class ExerciseProgressSeries with _$ExerciseProgressSeries {
  const ExerciseProgressSeries._();

  const factory ExerciseProgressSeries({required List<ProgressPoint> points}) =
      _ExerciseProgressSeries;

  /// No points — the exercise has no completed-session history.
  bool get isEmpty => points.isEmpty;

  /// Exactly one point — render the single-stat layout, not a trend line.
  bool get isSingle => points.length == 1;
}
