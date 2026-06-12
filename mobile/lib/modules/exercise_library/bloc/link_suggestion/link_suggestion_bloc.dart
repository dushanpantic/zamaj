import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';

import 'link_suggestion_event.dart';
import 'link_suggestion_state.dart';

class LinkSuggestionBloc
    extends Bloc<LinkSuggestionEvent, LinkSuggestionState> {
  LinkSuggestionBloc({
    required ProgramRepository programRepository,
    required ExerciseLibraryRepository exerciseLibraryRepository,
    LinkSuggester suggester = const LinkSuggester(),
  }) : _programRepository = programRepository,
       _libraryRepository = exerciseLibraryRepository,
       _suggester = suggester,
       super(const LinkSuggestionInitial()) {
    on<LinkSuggestionRequested>(_onRequested);
    on<LinkSuggestionRetryRequested>(_onRequested);
    on<LinkSuggestionClusterAccepted>(_onClusterAccepted);
    on<LinkSuggestionClusterSkipped>(_onClusterSkipped);
  }

  final ProgramRepository _programRepository;
  final ExerciseLibraryRepository _libraryRepository;
  final LinkSuggester _suggester;

  Future<void> _onRequested(
    LinkSuggestionEvent event,
    Emitter<LinkSuggestionState> emit,
  ) async {
    emit(const LinkSuggestionLoading());
    try {
      final clusters = await _buildClusters();
      emit(
        LinkSuggestionLoaded(
          clusters: clusters,
          dismissedNormalizedNames: const {},
        ),
      );
    } on DomainError catch (e) {
      emit(LinkSuggestionFailure(error: e));
    }
  }

  Future<void> _onClusterAccepted(
    LinkSuggestionClusterAccepted event,
    Emitter<LinkSuggestionState> emit,
  ) async {
    final current = state;
    if (current is! LinkSuggestionLoaded) return;
    final cluster = current.clusters.firstWhere(
      (c) => c.normalizedName == event.normalizedName,
      orElse: () => throw StateError('Cluster not found'),
    );
    emit(
      current.copyWith(
        applyingNormalizedName: () => event.normalizedName,
        lastError: () => null,
      ),
    );
    try {
      final library = await _libraryRepository.create(
        name: cluster.suggestedName,
        measurementType: cluster.measurementType,
        videoUrl: cluster.suggestedVideoUrl,
      );
      for (final ref in cluster.occurrences) {
        final exercise = await _programRepository.getExercise(ref.exerciseId);
        if (exercise == null) continue;
        if (exercise.libraryExerciseId != null) continue;
        await _programRepository.updateExercise(
          exercise.copyWith(libraryExerciseId: library.id),
        );
      }
      final dismissed = {
        ...current.dismissedNormalizedNames,
        event.normalizedName,
      };
      emit(
        current.copyWith(
          dismissedNormalizedNames: dismissed,
          applyingNormalizedName: () => null,
        ),
      );
    } on DomainError catch (e) {
      emit(
        current.copyWith(
          applyingNormalizedName: () => null,
          lastError: () => e,
        ),
      );
    }
  }

  Future<void> _onClusterSkipped(
    LinkSuggestionClusterSkipped event,
    Emitter<LinkSuggestionState> emit,
  ) async {
    final current = state;
    if (current is! LinkSuggestionLoaded) return;
    final dismissed = {
      ...current.dismissedNormalizedNames,
      event.normalizedName,
    };
    emit(current.copyWith(dismissedNormalizedNames: dismissed));
  }

  Future<List<LinkSuggestionCluster>> _buildClusters() async {
    final programs = await _programRepository.listPrograms();
    final aggregates = <ProgramAggregate>[];
    for (final program in programs) {
      final days = await _programRepository.listWorkoutDaysForProgram(
        program.id,
      );
      aggregates.add(_toAggregate(program, days));
    }
    return _suggester.suggest(aggregates);
  }

  ProgramAggregate _toAggregate(Program program, List<WorkoutDay> days) {
    return ProgramAggregate(
      id: program.id,
      name: program.name,
      createdAt: program.createdAt,
      updatedAt: program.updatedAt,
      schemaVersion: program.schemaVersion,
      workoutDays: [
        for (var dayIndex = 0; dayIndex < days.length; dayIndex++)
          _toDayAggregate(days[dayIndex], dayIndex),
      ],
    );
  }

  WorkoutDayAggregate _toDayAggregate(WorkoutDay day, int position) {
    return WorkoutDayAggregate(
      id: day.id,
      programId: day.programId,
      name: day.name,
      position: position,
      groups: [
        for (var i = 0; i < day.exerciseGroups.length; i++)
          _toGroupAggregate(day.exerciseGroups[i], i),
      ],
    );
  }

  ExerciseGroupAggregate _toGroupAggregate(ExerciseGroup group, int position) {
    return ExerciseGroupAggregate(
      id: group.id,
      workoutDayId: group.workoutDayId,
      kind: group.kind,
      role: group.role,
      position: position,
      exercises: [
        for (var i = 0; i < group.exercises.length; i++)
          _toExerciseAggregate(group.exercises[i], i),
      ],
    );
  }

  ExerciseAggregate _toExerciseAggregate(Exercise exercise, int position) {
    return ExerciseAggregate(
      id: exercise.id,
      groupId: exercise.exerciseGroupId,
      name: exercise.name,
      measurementType: exercise.measurementType,
      metadata: exercise.metadata,
      plannedRestSeconds: exercise.plannedRestSeconds,
      libraryExerciseId: exercise.libraryExerciseId,
      position: position,
      sets: [
        for (var i = 0; i < exercise.sets.length; i++)
          _toSetAggregate(exercise.sets[i], i),
      ],
    );
  }

  WorkoutSetAggregate _toSetAggregate(WorkoutSet set, int position) {
    return WorkoutSetAggregate(
      id: set.id,
      exerciseId: set.exerciseId,
      values: set.plannedValues,
      position: position,
    );
  }
}
