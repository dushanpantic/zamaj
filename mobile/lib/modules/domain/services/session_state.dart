import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';
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

    /// Back-compat shim derived from [openTargets]: the first open target as
    /// an [ActiveCursor], or [Cursor.completed] when the list is empty.
    /// Removed once the UI moves to consuming [openTargets] directly.
    required Cursor cursor,

    /// Back-compat shim: [SessionFlowEngine.suggestValuesFor] applied to the
    /// first open target. Removed alongside [cursor].
    ActualSetValues? suggestedValues,
  }) = _SessionState;
}
