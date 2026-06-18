import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_note.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
abstract class Session with _$Session {
  const Session._();

  const factory Session({
    required String id,
    required String workoutDayId,
    required SessionSnapshot snapshot,
    required List<SessionExercise> sessionExercises,
    required List<SessionNote> notes,
    required List<ExtraWork> extraWork,
    required DateTime startedAt,
    DateTime? endedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
    @Default(false) bool isDeload,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(() => _$SessionFromJson(json), json, 'Session');
}
