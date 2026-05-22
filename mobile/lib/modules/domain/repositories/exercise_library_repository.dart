/// Abstract contract for the global exercise library.
///
/// One row per movement, shared across all programs and sessions. All method
/// signatures are typed solely in domain terms (Req 10.1).
library;

import 'package:zamaj/modules/domain/models/library_exercise.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

abstract class ExerciseLibraryRepository {
  Future<LibraryExercise> create({
    required String name,
    required MeasurementType measurementType,
    String? videoUrl,
    String? cues,
  });

  Future<LibraryExercise?> get(String id);

  /// Returns active (non-archived) entries by default. Pass
  /// [includeArchived] = true for management screens.
  Future<List<LibraryExercise>> list({
    bool includeArchived = false,
    MeasurementType? measurementType,
    String? nameQuery,
  });

  Future<LibraryExercise> update(LibraryExercise entry);

  Future<LibraryExercise> archive(String id);
  Future<LibraryExercise> unarchive(String id);

  /// Case-insensitive trimmed lookup. Returns the matching entry if one
  /// exists (archived or active), null otherwise. Used by the collision
  /// check on "Add to library."
  Future<LibraryExercise?> findByNormalizedName(String name);
}
