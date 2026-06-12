import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

/// A reference back to a single template [Exercise] inside a [ProgramAggregate],
/// used to show the user where a cluster's occurrences come from.
class ExerciseReference extends Equatable {
  const ExerciseReference({
    required this.exerciseId,
    required this.exerciseName,
    required this.programId,
    required this.programName,
    required this.workoutDayId,
    required this.workoutDayName,
    required this.plannedSetCount,
  });

  final String exerciseId;
  final String exerciseName;
  final String programId;
  final String programName;
  final String workoutDayId;
  final String workoutDayName;
  final int plannedSetCount;

  @override
  List<Object?> get props => [
    exerciseId,
    exerciseName,
    programId,
    programName,
    workoutDayId,
    workoutDayName,
    plannedSetCount,
  ];
}

/// A group of unlinked template Exercises that all share the same normalized
/// name + measurement type and could be linked to a single [LibraryExercise].
class LinkSuggestionCluster extends Equatable {
  const LinkSuggestionCluster({
    required this.normalizedName,
    required this.measurementType,
    required this.suggestedName,
    required this.suggestedVideoUrl,
    required this.occurrences,
  });

  final String normalizedName;
  final MeasurementType measurementType;
  final String suggestedName;
  final String? suggestedVideoUrl;
  final List<ExerciseReference> occurrences;

  int get occurrenceCount => occurrences.length;

  @override
  List<Object?> get props => [
    normalizedName,
    measurementType,
    suggestedName,
    suggestedVideoUrl,
    occurrences,
  ];
}
