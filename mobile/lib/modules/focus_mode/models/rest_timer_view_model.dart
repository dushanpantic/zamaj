import 'package:freezed_annotation/freezed_annotation.dart';

part 'rest_timer_view_model.freezed.dart';

/// Snapshot of the inline rest-timer state.
///
/// Owned by [FocusModeBloc]; ticking is driven by `Timer.periodic(1s)` in
/// the bloc itself. Persistence/foreground notification is deliberately
/// out of scope for spec 6 — that lands in spec 7.
@freezed
abstract class RestTimerViewModel with _$RestTimerViewModel {
  const RestTimerViewModel._();

  const factory RestTimerViewModel({
    /// Coach-defined target rest in seconds, or null when the planned
    /// exercise doesn't specify rest. When null, the timer counts up
    /// without an "overtime" threshold.
    required int? plannedSeconds,

    /// Real seconds elapsed since [startedAt], not counting time spent
    /// paused.
    required int elapsedSeconds,

    /// Cumulative seconds added via the +15s control. Folded into the
    /// effective planned target so "remaining" reflects user extensions.
    required int extensionSeconds,

    /// True while the timer is paused. Tick events are ignored while
    /// paused.
    required bool isPaused,
  }) = _RestTimerViewModel;

  /// Effective planned target (planned + extensions). Null if no plan.
  int? get effectivePlannedSeconds =>
      plannedSeconds == null ? null : plannedSeconds! + extensionSeconds;

  /// Seconds remaining until the effective planned target, or null when no
  /// plan exists. Negative values mean the timer has gone over.
  int? get remainingSeconds {
    final target = effectivePlannedSeconds;
    if (target == null) return null;
    return target - elapsedSeconds;
  }

  /// True when an effective planned target exists and elapsed has passed it.
  bool get isOvertime {
    final remaining = remainingSeconds;
    return remaining != null && remaining < 0;
  }
}
