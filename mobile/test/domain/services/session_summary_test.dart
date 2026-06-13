import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('SessionSummary.fromSession', () {
    test('duration is the elapsed wall time between start and end', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0, 0),
        endedAt: DateTime.utc(2026, 5, 12, 18, 42, 18),
        exercises: const [],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.duration, const Duration(minutes: 42, seconds: 18));
    });

    test('an in-progress session reports zero duration', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0, 0),
        endedAt: null,
        exercises: const [],
      );

      expect(SessionSummary.fromSession(session).duration, Duration.zero);
    });

    test('counts completed working sets against planned working sets', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0),
        endedAt: DateTime.utc(2026, 5, 12, 19, 0),
        exercises: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100, 5), (100, 5), (100, 5)],
            actualRep: const [(100, 5), (100, 5)],
          ),
        ],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.completedWorkingSets, 2);
      expect(summary.plannedWorkingSets, 3);
    });

    test('excludes warmup-group sets from both completed and planned', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0),
        endedAt: DateTime.utc(2026, 5, 12, 19, 0),
        exercises: [
          _ExerciseSpec(
            name: 'Warmup Bike',
            measurementType: const MeasurementType.timeBased(),
            plannedTime: const [60, 60, 60],
            actualTime: const [60, 60, 60],
            role: ExerciseGroupRole.warmup,
          ),
          _ExerciseSpec(
            name: 'Squat',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
            ],
            actualRep: const [
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
              (100, 5),
            ],
          ),
        ],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.completedWorkingSets, 9);
      expect(summary.plannedWorkingSets, 10);
    });

    test('completed may exceed planned when extra sets are logged', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0),
        endedAt: DateTime.utc(2026, 5, 12, 19, 0),
        exercises: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100, 5), (100, 5)],
            actualRep: const [(100, 5), (100, 5), (100, 5)],
          ),
        ],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.completedWorkingSets, 3);
      expect(summary.plannedWorkingSets, 2);
    });

    test('volume sums weighted work only; bodyweight and time add nothing', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0),
        endedAt: DateTime.utc(2026, 5, 12, 19, 0),
        exercises: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100, 5), (80, 8)],
            actualRep: const [(100, 5), (80, 8)],
          ),
          _ExerciseSpec(
            name: 'Pushups',
            measurementType: const MeasurementType.bodyweight(),
            plannedBodyweightReps: const [12],
            actualBodyweightReps: const [12],
          ),
          _ExerciseSpec(
            name: 'Plank',
            measurementType: const MeasurementType.timeBased(),
            plannedTime: const [60],
            actualTime: const [60],
          ),
        ],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.weightedVolumeKg, 1140);
      expect(summary.hasWeightedVolume, isTrue);
    });

    test('reports no weighted volume when no weighted set was logged', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0),
        endedAt: DateTime.utc(2026, 5, 12, 19, 0),
        exercises: [
          _ExerciseSpec(
            name: 'Pushups',
            measurementType: const MeasurementType.bodyweight(),
            plannedBodyweightReps: const [12, 12],
            actualBodyweightReps: const [12, 12],
          ),
          _ExerciseSpec(
            name: 'Plank',
            measurementType: const MeasurementType.timeBased(),
            plannedTime: const [60],
            actualTime: const [60],
          ),
        ],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.weightedVolumeKg, 0);
      expect(summary.hasWeightedVolume, isFalse);
    });

    test('weighted sets inside a warmup group do not count toward volume', () {
      final session = _session(
        startedAt: DateTime.utc(2026, 5, 12, 18, 0),
        endedAt: DateTime.utc(2026, 5, 12, 19, 0),
        exercises: [
          _ExerciseSpec(
            name: 'Warmup Bench',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(40, 10)],
            actualRep: const [(40, 10)],
            role: ExerciseGroupRole.warmup,
          ),
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100, 5)],
            actualRep: const [(100, 5)],
          ),
        ],
      );

      final summary = SessionSummary.fromSession(session);

      expect(summary.weightedVolumeKg, 500);
    });
  });
}

// -----------------------------------------------------------------------------
// Fixture builders — a workout day of single-exercise groups, each carrying a
// planned set list (snapshot) and an executed set list (actuals).

class _ExerciseSpec {
  _ExerciseSpec({
    required this.name,
    required this.measurementType,
    this.plannedRep = const [],
    this.plannedTime = const [],
    this.plannedBodyweightReps = const [],
    this.actualRep = const [],
    this.actualTime = const [],
    this.actualBodyweightReps = const [],
    this.role = ExerciseGroupRole.main,
  });

  final String name;
  final MeasurementType measurementType;
  final List<(double, int)> plannedRep; // (weightKg, reps)
  final List<int> plannedTime;
  final List<int> plannedBodyweightReps;
  final List<(double, int)> actualRep;
  final List<int> actualTime;
  final List<int> actualBodyweightReps;
  final ExerciseGroupRole role;
}

Session _session({
  required DateTime startedAt,
  required DateTime? endedAt,
  required List<_ExerciseSpec> exercises,
}) {
  final t = DateTime.utc(2026, 5, 12);
  final workoutDay = WorkoutDay(
    id: 'wd-1',
    programId: 'p-1',
    name: 'Day',
    exerciseGroups: [
      for (var i = 0; i < exercises.length; i++)
        ExerciseGroup(
          id: 'g-$i',
          workoutDayId: 'wd-1',
          position: i,
          kind: const ExerciseGroupKind.single(),
          role: exercises[i].role,
          exercises: [_buildExercise(exercises[i], i)],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
    ],
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: t,
    schemaVersion: 1,
  );
  return Session(
    id: 'session-1',
    workoutDayId: workoutDay.id,
    snapshot: snapshot,
    sessionExercises: [
      for (var i = 0; i < exercises.length; i++)
        _buildSessionExercise(exercises[i], i),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}

Exercise _buildExercise(_ExerciseSpec spec, int idx) {
  final t = DateTime.utc(2026, 5, 12);
  final sets = <WorkoutSet>[];
  if (spec.measurementType is RepBasedMeasurement) {
    for (var i = 0; i < spec.plannedRep.length; i++) {
      final (kg, reps) = spec.plannedRep[i];
      sets.add(
        WorkoutSet(
          id: 'ws-$idx-$i',
          exerciseId: 'ex-$idx',
          position: i,
          measurementType: spec.measurementType,
          plannedValues: PlannedSetValues.repBased(
            weightKg: kg,
            repTarget: RepTarget.fixed(reps: reps),
          ),
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  } else if (spec.measurementType is TimeBasedMeasurement) {
    for (var i = 0; i < spec.plannedTime.length; i++) {
      sets.add(
        WorkoutSet(
          id: 'ws-$idx-$i',
          exerciseId: 'ex-$idx',
          position: i,
          measurementType: spec.measurementType,
          plannedValues: PlannedSetValues.timeBased(
            durationSeconds: spec.plannedTime[i],
          ),
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  } else {
    for (var i = 0; i < spec.plannedBodyweightReps.length; i++) {
      sets.add(
        WorkoutSet(
          id: 'ws-$idx-$i',
          exerciseId: 'ex-$idx',
          position: i,
          measurementType: spec.measurementType,
          plannedValues: PlannedSetValues.bodyweight(
            repTarget: RepTarget.fixed(reps: spec.plannedBodyweightReps[i]),
          ),
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  }
  return Exercise(
    id: 'ex-$idx',
    exerciseGroupId: 'g-$idx',
    position: 0,
    name: spec.name,
    measurementType: spec.measurementType,
    metadata: const ExerciseMetadata(),
    sets: sets,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}

SessionExercise _buildSessionExercise(_ExerciseSpec spec, int idx) {
  final t = DateTime.utc(2026, 5, 12);
  final executed = <ExecutedSet>[];
  if (spec.measurementType is RepBasedMeasurement) {
    for (var i = 0; i < spec.actualRep.length; i++) {
      final (kg, reps) = spec.actualRep[i];
      executed.add(
        ExecutedSet(
          id: 'es-$idx-$i',
          sessionExerciseId: 'sx-$idx',
          position: i,
          measurementType: spec.measurementType,
          actualValues: ActualSetValues.repBased(weightKg: kg, reps: reps),
          completedAt: t,
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  } else if (spec.measurementType is TimeBasedMeasurement) {
    for (var i = 0; i < spec.actualTime.length; i++) {
      executed.add(
        ExecutedSet(
          id: 'es-$idx-$i',
          sessionExerciseId: 'sx-$idx',
          position: i,
          measurementType: spec.measurementType,
          actualValues: ActualSetValues.timeBased(
            durationSeconds: spec.actualTime[i],
          ),
          completedAt: t,
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  } else {
    for (var i = 0; i < spec.actualBodyweightReps.length; i++) {
      executed.add(
        ExecutedSet(
          id: 'es-$idx-$i',
          sessionExerciseId: 'sx-$idx',
          position: i,
          measurementType: spec.measurementType,
          actualValues: ActualSetValues.bodyweight(
            reps: spec.actualBodyweightReps[i],
          ),
          completedAt: t,
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  }
  return SessionExercise(
    id: 'sx-$idx',
    sessionId: 'session-1',
    position: idx,
    plannedExerciseIdInSnapshot: 'ex-$idx',
    state: const ExerciseState.completed(),
    executedSets: executed,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}
