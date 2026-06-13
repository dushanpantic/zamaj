import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository(this.exercise);

  Exercise exercise;
  Exercise? lastSaved;

  @override
  Future<Exercise?> getExercise(String exerciseId) async => exercise;

  @override
  Future<Exercise> updateExercise(Exercise updated) async {
    lastSaved = updated;
    return updated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLinkLauncher implements ExternalLinkLauncher {
  @override
  Future<ExternalLinkResult> launch(Uri url) async =>
      const ExternalLinkOpened();
}

final _now = DateTime.utc(2026, 1, 1);

Exercise _repExercise({
  required int setCount,
  double weightKg = 100,
  int reps = 5,
}) {
  return Exercise(
    id: 'ex1',
    exerciseGroupId: 'g1',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: 180,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: 'set$i',
          exerciseId: 'ex1',
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: weightKg,
            repTarget: RepTarget.fixed(reps: reps),
          ),
          createdAt: _now,
          updatedAt: _now,
          schemaVersion: SchemaVersions.domain,
        ),
    ],
    createdAt: _now,
    updatedAt: _now,
    schemaVersion: SchemaVersions.domain,
  );
}

Exercise _repRangeExercise({required int setCount, int min = 6, int max = 8}) {
  return Exercise(
    id: 'ex1',
    exerciseGroupId: 'g1',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: 180,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: 'set$i',
          exerciseId: 'ex1',
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.range(minReps: min, maxReps: max),
          ),
          createdAt: _now,
          updatedAt: _now,
          schemaVersion: SchemaVersions.domain,
        ),
    ],
    createdAt: _now,
    updatedAt: _now,
    schemaVersion: SchemaVersions.domain,
  );
}

Exercise _timeExercise({required int setCount, int durationSeconds = 60}) {
  return Exercise(
    id: 'ex1',
    exerciseGroupId: 'g1',
    position: 0,
    name: 'Plank',
    measurementType: const MeasurementType.timeBased(),
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: 180,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: 'set$i',
          exerciseId: 'ex1',
          position: i,
          measurementType: const MeasurementType.timeBased(),
          plannedValues: PlannedSetValues.timeBased(
            durationSeconds: durationSeconds,
          ),
          createdAt: _now,
          updatedAt: _now,
          schemaVersion: SchemaVersions.domain,
        ),
    ],
    createdAt: _now,
    updatedAt: _now,
    schemaVersion: SchemaVersions.domain,
  );
}

Future<ExerciseEditorBloc> _opened(_FakeProgramRepository repo) async {
  final bloc = ExerciseEditorBloc(
    programRepository: repo,
    externalLinkLauncher: _FakeLinkLauncher(),
  );
  bloc.add(const ExerciseEditorOpened(exerciseId: 'ex1'));
  await pumpEventQueue();
  return bloc;
}

ExerciseEditorEditing _editing(ExerciseEditorBloc bloc) =>
    bloc.state as ExerciseEditorEditing;

List<String> _weights(ExerciseEditorBloc bloc) => _editing(bloc).draft.sets
    .map(
      (s) => switch (s.values) {
        PlannedSetDraftRepBased(:final weightInput) => weightInput,
        PlannedSetDraftTimeBased(:final weightInput) => weightInput,
        PlannedSetDraftBodyweight() => '',
      },
    )
    .toList();

List<String> _reps(ExerciseEditorBloc bloc) => _editing(bloc).draft.sets
    .map(
      (s) => switch (s.values) {
        PlannedSetDraftRepBased(:final repsInput) => repsInput,
        PlannedSetDraftBodyweight(:final repsInput) => repsInput,
        PlannedSetDraftTimeBased() => '',
      },
    )
    .toList();

List<String> _durations(ExerciseEditorBloc bloc) => _editing(bloc).draft.sets
    .map(
      (s) => switch (s.values) {
        PlannedSetDraftTimeBased(:final durationInput) => durationInput,
        _ => '',
      },
    )
    .toList();

void main() {
  group('AllSetsWeightChanged', () {
    test('sets the weight on every set', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsWeightChanged(rawInput: '110'));
      await pumpEventQueue();

      expect(_weights(bloc), ['110', '110', '110', '110']);
    });

    test('clearing the weight blocks saving', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsWeightChanged(rawInput: ''));
      await pumpEventQueue();

      expect(_editing(bloc).validation.canSave, isFalse);
    });
  });

  group('AllSetsRepsChanged', () {
    test('sets the reps on every set', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsRepsChanged(rawInput: '8'));
      await pumpEventQueue();

      expect(_reps(bloc), ['8', '8', '8', '8']);
    });
  });

  group('AllSetsDurationChanged', () {
    test('sets the duration on every time-based set', () async {
      final repo = _FakeProgramRepository(_timeExercise(setCount: 3));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsDurationChanged(rawInput: '90'));
      await pumpEventQueue();

      expect(_durations(bloc), ['90', '90', '90']);
    });
  });

  group('AllSetsWeightBumped', () {
    test('bumps the weight on every set', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsWeightBumped(delta: 2.5));
      await pumpEventQueue();

      expect(_weights(bloc), ['102.5', '102.5', '102.5', '102.5']);
    });
  });

  group('AllSetsRepsBumped', () {
    test('bumps every set, preserving rep ranges', () async {
      final repo = _FakeProgramRepository(_repRangeExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsRepsBumped(delta: 1));
      await pumpEventQueue();

      expect(_reps(bloc), ['7-9', '7-9', '7-9', '7-9']);
    });
  });

  group('AllSetsDurationBumped', () {
    test('bumps the duration on every time-based set', () async {
      final repo = _FakeProgramRepository(_timeExercise(setCount: 3));
      final bloc = await _opened(repo);

      bloc.add(const AllSetsDurationBumped(delta: 5));
      await pumpEventQueue();

      expect(_durations(bloc), ['65', '65', '65']);
    });
  });

  group('PlannedSetCountChanged', () {
    test('grows by appending sets that inherit the uniform value', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const PlannedSetCountChanged(count: 6));
      await pumpEventQueue();

      expect(_weights(bloc), List.filled(6, '100.0'));
      expect(_reps(bloc), List.filled(6, '5'));
    });

    test('shrinks by dropping from the end', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const PlannedSetCountChanged(count: 2));
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, hasLength(2));
    });

    test('clamps to at least one set', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const PlannedSetCountChanged(count: 0));
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, hasLength(1));
    });

    test('clamps to at most twenty sets', () async {
      final repo = _FakeProgramRepository(_repExercise(setCount: 4));
      final bloc = await _opened(repo);

      bloc.add(const PlannedSetCountChanged(count: 25));
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, hasLength(20));
    });
  });

  group('AllSetsFlattenedToFirst', () {
    test('sets every set to the first set value', () async {
      final repo = _FakeProgramRepository(
        Exercise(
          id: 'ex1',
          exerciseGroupId: 'g1',
          position: 0,
          name: 'Bench',
          measurementType: const MeasurementType.repBased(),
          metadata: ExerciseMetadata.empty,
          plannedRestSeconds: 180,
          sets: [
            for (var i = 0; i < 4; i++)
              WorkoutSet(
                id: 'set$i',
                exerciseId: 'ex1',
                position: i,
                measurementType: const MeasurementType.repBased(),
                plannedValues: PlannedSetValues.repBased(
                  weightKg: 80 + i * 10,
                  repTarget: RepTarget.fixed(reps: 5),
                ),
                createdAt: _now,
                updatedAt: _now,
                schemaVersion: SchemaVersions.domain,
              ),
          ],
          createdAt: _now,
          updatedAt: _now,
          schemaVersion: SchemaVersions.domain,
        ),
      );
      final bloc = await _opened(repo);

      bloc.add(const AllSetsFlattenedToFirst());
      await pumpEventQueue();

      expect(_weights(bloc), ['80.0', '80.0', '80.0', '80.0']);
    });
  });

  group('save round-trips uniform edits', () {
    test(
      'a bumped exercise saves four sets with equal planned values',
      () async {
        final repo = _FakeProgramRepository(_repExercise(setCount: 4));
        final bloc = await _opened(repo);

        bloc.add(const AllSetsWeightBumped(delta: 2.5));
        await pumpEventQueue();
        bloc.add(const ExerciseSavePressed());
        await pumpEventQueue();

        final saved = repo.lastSaved!;
        expect(saved.sets, hasLength(4));
        final values = saved.sets.map((s) => s.plannedValues).toSet();
        expect(values, hasLength(1));
        expect(
          saved.sets.first.plannedValues,
          PlannedSetValues.repBased(
            weightKg: 102.5,
            repTarget: RepTarget.fixed(reps: 5),
          ),
        );
      },
    );
  });
}
