import 'package:zamaj/modules/domain/domain.dart';

/// Route arguments for the exercise-progress screen.
///
/// [libraryExerciseId] is nullable: a session-review exercise that was never
/// linked to a Library entry has no id, which the bloc maps to the "unlinked"
/// guidance state. [measurementType] gates the weighted-only (v1) feature, and
/// [displayName] titles the screen.
final class ExerciseProgressArgs {
  const ExerciseProgressArgs({
    required this.libraryExerciseId,
    required this.measurementType,
    required this.displayName,
  });

  final String? libraryExerciseId;
  final MeasurementType measurementType;
  final String displayName;
}
