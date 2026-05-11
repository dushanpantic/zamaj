import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'cursor.freezed.dart';
part 'cursor.g.dart';

@Freezed(unionKey: 'type')
sealed class Cursor with _$Cursor {
  const factory Cursor.active({
    required String sessionExerciseId,
    required int setIndex,
  }) = ActiveCursor;

  const factory Cursor.completed() = CompletedCursor;

  factory Cursor.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(() => _$CursorFromJson(json), json, 'Cursor');
}
