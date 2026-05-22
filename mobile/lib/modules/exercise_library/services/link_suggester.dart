import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/models/link_suggestion_cluster.dart';

/// Pure-Dart service that groups unlinked template exercises across all
/// programs into clusters that could share a single [LibraryExercise].
///
/// An exercise is "unlinked" when [ExerciseAggregate.libraryExerciseId] is null.
/// Clusters key on `(name.trim().toLowerCase(), measurementType)`.
class LinkSuggester {
  const LinkSuggester();

  List<LinkSuggestionCluster> suggest(List<ProgramAggregate> programs) {
    final buckets = <_ClusterKey, _ClusterBuilder>{};

    for (final program in programs) {
      for (final day in program.workoutDays) {
        for (final group in day.groups) {
          for (final exercise in group.exercises) {
            if (exercise.libraryExerciseId != null) continue;
            final normalized = exercise.name.trim().toLowerCase();
            if (normalized.isEmpty) continue;
            final key = _ClusterKey(normalized, exercise.measurementType);
            final builder = buckets.putIfAbsent(
              key,
              () => _ClusterBuilder(
                normalizedName: normalized,
                measurementType: exercise.measurementType,
              ),
            );
            builder.add(
              exerciseName: exercise.name.trim(),
              videoUrl: exercise.metadata.videoUrl,
              reference: ExerciseReference(
                exerciseId: exercise.id,
                exerciseName: exercise.name.trim(),
                programId: program.id,
                programName: program.name,
                workoutDayId: day.id,
                workoutDayName: day.name,
                plannedSetCount: exercise.sets.length,
              ),
            );
          }
        }
      }
    }

    final clusters = buckets.values.map((b) => b.build()).toList();
    clusters.sort((a, b) {
      final byCount = b.occurrenceCount.compareTo(a.occurrenceCount);
      if (byCount != 0) return byCount;
      return a.suggestedName.toLowerCase().compareTo(
        b.suggestedName.toLowerCase(),
      );
    });
    return clusters;
  }
}

class _ClusterKey {
  const _ClusterKey(this.normalizedName, this.measurementType);

  final String normalizedName;
  final MeasurementType measurementType;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ClusterKey &&
          normalizedName == other.normalizedName &&
          measurementType == other.measurementType;

  @override
  int get hashCode => Object.hash(normalizedName, measurementType);
}

class _ClusterBuilder {
  _ClusterBuilder({
    required this.normalizedName,
    required this.measurementType,
  });

  final String normalizedName;
  final MeasurementType measurementType;
  final List<ExerciseReference> _occurrences = [];
  String _suggestedName = '';
  String? _suggestedVideoUrl;

  void add({
    required String exerciseName,
    required String? videoUrl,
    required ExerciseReference reference,
  }) {
    _occurrences.add(reference);
    if (exerciseName.length > _suggestedName.length) {
      _suggestedName = exerciseName;
    }
    if (_suggestedVideoUrl == null && videoUrl != null && videoUrl.isNotEmpty) {
      _suggestedVideoUrl = videoUrl;
    }
  }

  LinkSuggestionCluster build() {
    return LinkSuggestionCluster(
      normalizedName: normalizedName,
      measurementType: measurementType,
      suggestedName: _suggestedName,
      suggestedVideoUrl: _suggestedVideoUrl,
      occurrences: List.unmodifiable(_occurrences),
    );
  }
}
