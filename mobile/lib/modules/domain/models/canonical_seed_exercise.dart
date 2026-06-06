import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';

part 'canonical_seed_exercise.freezed.dart';

/// A single entry in the embedded canonical exercise catalog.
///
/// A pure value object: it carries no timestamps or schema version — the
/// repository stamps those when seeding. Built by [CanonicalSeedCatalog.parse]
/// from the authored asset, never persisted directly.
@freezed
abstract class CanonicalSeedExercise with _$CanonicalSeedExercise {
  CanonicalSeedExercise._() {
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

  factory CanonicalSeedExercise({
    required String id,
    required String name,
    required MeasurementType measurementType,
    required Prominence prominence,
    required List<MuscleGroup> primaryMuscles,
    @Default(<MuscleGroup>[]) List<MuscleGroup> secondaryMuscles,
    String? videoUrl,
    String? cues,
  }) = _CanonicalSeedExercise;
}
