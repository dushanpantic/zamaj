import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';

part 'library_exercise.freezed.dart';
part 'library_exercise.g.dart';

@freezed
abstract class LibraryExercise with _$LibraryExercise {
  LibraryExercise._() {
    if (id.length != 36) {
      throw ValidationError(
        entityId: id,
        invariant: 'id_not_uuid_v4',
        message: 'id must be canonical UUIDv4 (36 chars), got ${id.length}',
      );
    }
    if (name != name.trim() || name.isEmpty) {
      throw ValidationError(
        entityId: id,
        invariant: 'name_not_trimmed_or_empty',
        message: 'name must be trimmed and non-empty, got "$name"',
      );
    }
    if (videoUrl != null && videoUrl!.isEmpty) {
      throw ValidationError(
        entityId: id,
        invariant: 'video_url_empty',
        message: 'videoUrl must be null or non-empty, got ""',
      );
    }
    if (cues != null && cues!.isEmpty) {
      throw ValidationError(
        entityId: id,
        invariant: 'cues_empty',
        message: 'cues must be null or non-empty, got ""',
      );
    }
    final overlap = primaryMuscles.toSet().intersection(
      secondaryMuscles.toSet(),
    );
    if (overlap.isNotEmpty) {
      throw ValidationError(
        entityId: id,
        invariant: 'muscles_not_disjoint',
        message:
            'primary and secondary muscles must be disjoint, '
            'overlap: ${overlap.map((m) => m.name).join(', ')}',
      );
    }
  }

  factory LibraryExercise({
    required String id,
    required String name,
    required MeasurementType measurementType,
    @Default(Prominence.common) Prominence prominence,
    @Default(<MuscleGroup>[]) List<MuscleGroup> primaryMuscles,
    @Default(<MuscleGroup>[]) List<MuscleGroup> secondaryMuscles,
    @Default(LibrarySource.user) LibrarySource source,
    String? videoUrl,
    String? cues,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _LibraryExercise;

  factory LibraryExercise.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$LibraryExerciseFromJson(json),
        json,
        'LibraryExercise',
      );
}
