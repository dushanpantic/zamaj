import 'package:freezed_annotation/freezed_annotation.dart';

part 'stopwatch_view_model.freezed.dart';

/// Snapshot of the time-based set countdown.
///
/// Only relevant when the focused exercise has a [TimeBasedMeasurement]. The
/// countdown is a guide for a prescribed hold: it counts down from the set
/// duration and the logged value is that duration, not the elapsed time.
///
/// Three phases: idle (showing the target), running (counting down), and a
/// brief [isFinished] flash that holds 00:00 for a beat before the bloc
/// resets back to idle.
@freezed
abstract class StopwatchViewModel with _$StopwatchViewModel {
  const factory StopwatchViewModel({
    required bool isRunning,
    required int elapsedSeconds,
    @Default(false) bool isFinished,
  }) = _StopwatchViewModel;

  /// A fresh, idle stopwatch at 0 seconds.
  factory StopwatchViewModel.idle() =>
      const StopwatchViewModel(isRunning: false, elapsedSeconds: 0);
}
