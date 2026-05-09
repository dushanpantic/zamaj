import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'session_note.freezed.dart';
part 'session_note.g.dart';

@freezed
abstract class SessionNote with _$SessionNote {
  const SessionNote._();

  const factory SessionNote({
    required String id,
    required String sessionId,
    required String body,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _SessionNote;

  factory SessionNote.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$SessionNoteFromJson(json),
        json,
        'SessionNote',
      );
}
