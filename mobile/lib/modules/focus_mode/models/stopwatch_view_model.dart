import 'package:freezed_annotation/freezed_annotation.dart';

part 'stopwatch_view_model.freezed.dart';

/// Snapshot of the time-based set stopwatch.
///
/// Only relevant when the cursor exercise has a [TimeBasedMeasurement]. The
/// user starts the stopwatch when they begin the hold, stops it when done,
/// and its elapsed seconds is written into the actual-values draft.
@freezed
abstract class StopwatchViewModel with _$StopwatchViewModel {
  const factory StopwatchViewModel({
    required bool isRunning,
    required int elapsedSeconds,
  }) = _StopwatchViewModel;

  /// A fresh, idle stopwatch at 0 seconds.
  factory StopwatchViewModel.idle() =>
      const StopwatchViewModel(isRunning: false, elapsedSeconds: 0);
}
