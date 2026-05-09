import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'exercise_metadata.freezed.dart';
part 'exercise_metadata.g.dart';

@freezed
abstract class ExerciseMetadata with _$ExerciseMetadata {
  const factory ExerciseMetadata({String? notes, String? videoUrl}) =
      _ExerciseMetadata;

  factory ExerciseMetadata.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExerciseMetadataFromJson(json),
        json,
        'ExerciseMetadata',
      );

  static const empty = ExerciseMetadata();
}
