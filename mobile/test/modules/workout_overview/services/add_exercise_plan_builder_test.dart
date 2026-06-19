import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/services/add_exercise_plan_builder.dart';

final _t = DateTime.utc(2025);

LibraryExercise _libraryEntry({
  required String id,
  String name = 'Cable Fly',
  String? videoUrl,
}) => LibraryExercise(
  id: id,
  name: name,
  measurementType: const MeasurementType.repBased(),
  videoUrl: videoUrl,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

PlannedSetValues _pv() => PlannedSetValues.repBased(
  weightKg: 60,
  repTarget: RepTarget.fixed(reps: 12),
);

/// A session with one snapshot exercise linked to [snapshotLibraryId] (or
/// unlinked when null), plus the given [added] session exercises.
Session _session({
  String? snapshotLibraryId,
  List<SessionExercise> added = const [],
}) {
  final exercise = Exercise(
    id: 'planned-real',
    exerciseGroupId: 'g',
    position: 0,
    name: 'Squat',
    measurementType: const MeasurementType.repBased(),
    metadata: const ExerciseMetadata(),
    libraryExerciseId: snapshotLibraryId,
    sets: [
      WorkoutSet(
        id: 'ws-0',
        exerciseId: 'planned-real',
        position: 0,
        measurementType: const MeasurementType.repBased(),
        plannedValues: _pv(),
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ],
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
  final workoutDay = WorkoutDay(
    id: 'wd',
    programId: 'p',
    name: 'D',
    exerciseGroups: [
      ExerciseGroup(
        id: 'g',
        workoutDayId: 'wd',
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercise],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ],
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: _t,
    schemaVersion: 1,
  );
  return Session(
    id: 'session-1',
    workoutDayId: 'wd',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'se-snap',
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: 'planned-real',
        state: const ExerciseState.unfinished(),
        executedSets: const [],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
      ...added,
    ],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

SessionExercise _addedSe({
  required String id,
  String? libraryExerciseId,
  String name = 'Added',
}) => SessionExercise(
  id: id,
  sessionId: 'session-1',
  position: 5,
  plannedExerciseIdInSnapshot: 'synthetic-$id-000000000000000000000',
  state: const ExerciseState.unfinished(),
  executedSets: const [],
  addedPlan: AddedExercisePlan(
    name: name,
    measurementType: const MeasurementType.repBased(),
    plannedValues: _pv(),
    setCount: 3,
    libraryExerciseId: libraryExerciseId,
  ),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

void main() {
  const libA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const libC = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

  group('AddExercisePlanBuilder.excludedLibraryIds', () {
    test('collects every library-linked movement (snapshot + added), '
        'ignores one-offs', () {
      final session = _session(
        snapshotLibraryId: libA,
        added: [
          _addedSe(id: 'se-added-lib', libraryExerciseId: libC),
          _addedSe(id: 'se-added-oneoff'), // null library id
        ],
      );
      expect(
        AddExercisePlanBuilder.excludedLibraryIds(session),
        {libA, libC},
      );
    });

    test('an unlinked snapshot exercise contributes nothing', () {
      final session = _session(snapshotLibraryId: null);
      expect(AddExercisePlanBuilder.excludedLibraryIds(session), isEmpty);
    });

    test('excludeSessionExerciseId drops one exercise from the set', () {
      final session = _session(snapshotLibraryId: libA);
      expect(
        AddExercisePlanBuilder.excludedLibraryIds(
          session,
          excludeSessionExerciseId: 'se-snap',
        ),
        isEmpty,
      );
    });
  });

  group('AddExercisePlanBuilder.fromLibrary', () {
    test('maps name/measurementType/libraryExerciseId/metadata from the entry '
        'and planned values + set count from inputs', () {
      final entry = _libraryEntry(id: libA, videoUrl: 'https://v');
      final plan = AddExercisePlanBuilder.fromLibrary(
        entry: entry,
        plannedValues: _pv(),
        setCount: 4,
      );
      expect(plan.name, 'Cable Fly');
      expect(plan.measurementType, const MeasurementType.repBased());
      expect(plan.libraryExerciseId, libA);
      expect(plan.metadata?.videoUrl, 'https://v');
      expect(plan.setCount, 4);
      expect(plan.plannedValues, _pv());
    });
  });

  group('AddExercisePlanBuilder.oneOff', () {
    test('maps name + chosen measurement type, leaving libraryExerciseId null',
        () {
      final plan = AddExercisePlanBuilder.oneOff(
        name: '  Sled Push  ',
        measurementType: const MeasurementType.timeBased(),
        plannedValues: const PlannedSetValues.timeBased(durationSeconds: 30),
        setCount: 2,
      );
      expect(plan.name, 'Sled Push'); // trimmed
      expect(plan.measurementType, const MeasurementType.timeBased());
      expect(plan.libraryExerciseId, isNull);
    });

    test('rejects an empty name', () {
      expect(
        () => AddExercisePlanBuilder.oneOff(
          name: '   ',
          measurementType: const MeasurementType.repBased(),
          plannedValues: _pv(),
          setCount: 3,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects setCount < 1', () {
      expect(
        () => AddExercisePlanBuilder.oneOff(
          name: 'Sled Push',
          measurementType: const MeasurementType.repBased(),
          plannedValues: _pv(),
          setCount: 0,
        ),
        throwsA(isA<ValidationError>()),
      );
    });
  });
}
