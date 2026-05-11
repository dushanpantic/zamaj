import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';

part 'session_state.freezed.dart';
part 'session_state.g.dart';

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    required Session session,
    required Cursor cursor,
    ActualSetValues? suggestedValues,
  }) = _SessionState;
}
