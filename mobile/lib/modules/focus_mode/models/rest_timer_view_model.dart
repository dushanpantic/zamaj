import 'package:freezed_annotation/freezed_annotation.dart';

part 'rest_timer_view_model.freezed.dart';

/// Snapshot of the inline rest-timer state.
///
/// Owned by [FocusModeBloc]; ticking is driven by `Timer.periodic(1s)` in
/// the bloc itself. The timer always has a planned target — when the
/// planned exercise has no rest, the bloc skips starting one rather than
/// surfacing an open-ended count-up. The timer auto-dismisses when
/// elapsed catches up to planned; there is no overtime state.
@freezed
abstract class RestTimerViewModel with _$RestTimerViewModel {
  const RestTimerViewModel._();

  const factory RestTimerViewModel({
    required int plannedSeconds,
    required int elapsedSeconds,
  }) = _RestTimerViewModel;

  /// Seconds remaining until the planned target. Never negative — the
  /// bloc dismisses the timer the moment elapsed catches up.
  int get remainingSeconds {
    final r = plannedSeconds - elapsedSeconds;
    return r < 0 ? 0 : r;
  }

  /// Fraction of the rest still ahead, in `[0, 1]`. Drives the shrinking
  /// progress bar.
  double get remainingFraction {
    if (plannedSeconds <= 0) return 0;
    final r = remainingSeconds / plannedSeconds;
    if (r < 0) return 0;
    if (r > 1) return 1;
    return r;
  }
}
