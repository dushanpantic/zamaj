import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/log_target.dart';

part 'session_state.freezed.dart';

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    required Session session,

    /// One [LogTarget] for every currently-loggable exercise (state
    /// `unfinished` or `replaced` with `executedSets.length <
    /// plannedSetCount`), in position order.
    required List<LogTarget> openTargets,

    /// True when every exercise is in a terminal state with its planned-set
    /// quota satisfied (`completed`, `skipped`, or `replaced` with all
    /// substitute sets logged).
    required bool isComplete,
  }) = _SessionState;
}
