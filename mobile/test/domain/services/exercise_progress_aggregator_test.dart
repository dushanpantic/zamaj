import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// A canonical UUIDv4-shaped id (36 chars) — [Exercise] validates that a
/// non-null `libraryExerciseId` is exactly 36 characters.
const benchLibraryId = '11111111-1111-4111-8111-111111111111';
const otherLibraryId = '22222222-2222-4222-8222-222222222222';

final _t0 = DateTime.utc(2024);

void main() {
  group('ProgressPoint', () {
    test(
      'carries date, top-set weight, reps, programId, and source day name',
      () {
        final point = ProgressPoint(
          date: DateTime.utc(2026, 3, 1),
          topSetWeightKg: 80,
          reps: 8,
          programId: 'prog-1',
          sourceWorkoutDayName: 'Push',
        );

        expect(point.date, DateTime.utc(2026, 3, 1));
        expect(point.topSetWeightKg, 80);
        expect(point.reps, 8);
        expect(point.programId, 'prog-1');
        expect(point.sourceWorkoutDayName, 'Push');
      },
    );

    test('rejects a negative top-set weight', () {
      expect(
        () => ProgressPoint(
          date: DateTime.utc(2026),
          topSetWeightKg: -1,
          reps: 5,
          programId: 'p',
          sourceWorkoutDayName: 'd',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects a weight off the 0.5 kg grid', () {
      expect(
        () => ProgressPoint(
          date: DateTime.utc(2026),
          topSetWeightKg: 80.25,
          reps: 5,
          programId: 'p',
          sourceWorkoutDayName: 'd',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('rejects negative reps', () {
      expect(
        () => ProgressPoint(
          date: DateTime.utc(2026),
          topSetWeightKg: 80,
          reps: -1,
          programId: 'p',
          sourceWorkoutDayName: 'd',
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('accepts zero weight and zero reps (the boundary)', () {
      expect(
        () => ProgressPoint(
          date: DateTime.utc(2026),
          topSetWeightKg: 0,
          reps: 0,
          programId: 'p',
          sourceWorkoutDayName: 'd',
        ),
        returnsNormally,
      );
    });
  });

  group('ExerciseProgressSeries', () {
    ProgressPoint pointAt(double weightKg) => ProgressPoint(
      date: DateTime.utc(2026),
      topSetWeightKg: weightKg,
      reps: 5,
      programId: 'p',
      sourceWorkoutDayName: 'd',
    );

    test('empty series reports isEmpty and not isSingle', () {
      const series = ExerciseProgressSeries(points: []);
      expect(series.isEmpty, isTrue);
      expect(series.isSingle, isFalse);
    });

    test('single-point series reports isSingle and not isEmpty', () {
      final series = ExerciseProgressSeries(points: [pointAt(80)]);
      expect(series.isEmpty, isFalse);
      expect(series.isSingle, isTrue);
    });

    test('multi-point series is neither empty nor single', () {
      final series = ExerciseProgressSeries(points: [pointAt(80), pointAt(90)]);
      expect(series.isEmpty, isFalse);
      expect(series.isSingle, isFalse);
    });
  });

  group('ExerciseProgressAggregator.compute', () {
    test('one point per session, cross-program, ordered oldest first', () {
      final feb = _session(
        id: 's-ppl',
        startedAt: DateTime.utc(2026, 2, 15),
        endedAt: DateTime.utc(2026, 2, 15, 1),
        programId: 'ppl',
        workoutDayName: 'PPL Push',
        repBasedSets: const [(weightKg: 100, reps: 5)],
      );
      final jan = _session(
        id: 's-5x5',
        startedAt: DateTime.utc(2026, 1, 10),
        endedAt: DateTime.utc(2026, 1, 10, 1),
        programId: 'fivebyfive',
        workoutDayName: '5x5 Day A',
        repBasedSets: const [(weightKg: 90, reps: 5)],
      );

      // Deliberately pass newest first to prove the aggregator re-sorts.
      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [feb, jan],
      );

      expect(series.points, hasLength(2));
      expect(series.points[0].topSetWeightKg, 90);
      expect(series.points[0].programId, 'fivebyfive');
      expect(series.points[0].sourceWorkoutDayName, '5x5 Day A');
      expect(series.points[1].topSetWeightKg, 100);
      expect(series.points[1].programId, 'ppl');
      expect(series.points[1].sourceWorkoutDayName, 'PPL Push');
    });

    test('a point carries weight, reps, and the session date', () {
      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [
          _session(
            id: 's',
            startedAt: DateTime.utc(2026, 3, 1),
            endedAt: DateTime.utc(2026, 3, 1, 1),
            repBasedSets: const [(weightKg: 80, reps: 8)],
          ),
        ],
      );

      expect(series.points, hasLength(1));
      expect(series.points.single.date, DateTime.utc(2026, 3, 1));
      expect(series.points.single.topSetWeightKg, 80);
      expect(series.points.single.reps, 8);
    });

    test('tie on weight is broken by the higher rep count', () {
      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [
          _session(
            id: 's',
            startedAt: DateTime.utc(2026, 3, 1),
            endedAt: DateTime.utc(2026, 3, 1, 1),
            repBasedSets: const [
              (weightKg: 100, reps: 3),
              (weightKg: 100, reps: 6),
            ],
          ),
        ],
      );

      expect(series.points.single.topSetWeightKg, 100);
      expect(series.points.single.reps, 6);
    });

    test('only completed (ended) sessions contribute a point', () {
      final inProgress = _session(
        id: 's-open',
        startedAt: DateTime.utc(2026, 3, 2),
        endedAt: null,
        repBasedSets: const [(weightKg: 120, reps: 3)],
      );
      final completed = _session(
        id: 's-done',
        startedAt: DateTime.utc(2026, 3, 1),
        endedAt: DateTime.utc(2026, 3, 1, 1),
        repBasedSets: const [(weightKg: 100, reps: 5)],
      );

      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [inProgress, completed],
      );

      expect(series.points, hasLength(1));
      expect(series.points.single.topSetWeightKg, 100);
    });

    test('sessions without the exercise contribute no point', () {
      final session = _session(
        id: 's',
        startedAt: DateTime.utc(2026, 3, 1),
        endedAt: DateTime.utc(2026, 3, 1, 1),
        // Snapshot exercise is linked to a *different* library entry.
        exerciseLibraryId: otherLibraryId,
        repBasedSets: const [(weightKg: 100, reps: 5)],
      );

      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [session],
      );

      expect(series.points, isEmpty);
    });

    test('non-repBased linked exercise contributes no point', () {
      final timeSession = _timeBasedSession(
        id: 's-time',
        startedAt: DateTime.utc(2026, 3, 1),
        endedAt: DateTime.utc(2026, 3, 1, 1),
      );

      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [timeSession],
      );

      expect(series.points, isEmpty);
    });

    test('empty series when no completed sessions contain the exercise', () {
      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: const [],
      );
      expect(series.isEmpty, isTrue);
    });

    test('single-point series with exactly one matching session', () {
      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [
          _session(
            id: 's',
            startedAt: DateTime.utc(2026, 3, 1),
            endedAt: DateTime.utc(2026, 3, 1, 1),
            repBasedSets: const [(weightKg: 70, reps: 10)],
          ),
        ],
      );
      expect(series.isSingle, isTrue);
      expect(series.points.single.topSetWeightKg, 70);
      expect(series.points.single.reps, 10);
    });

    test('bodyweight linked exercise contributes no point', () {
      final bodyweightSession = _bodyweightSession(
        id: 's-bw',
        startedAt: DateTime.utc(2026, 3, 1),
        endedAt: DateTime.utc(2026, 3, 1, 1),
      );

      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [bodyweightSession],
      );

      expect(series.points, isEmpty);
    });

    test('ties on startedAt are ordered deterministically by session id', () {
      final later = _session(
        id: 's-b',
        startedAt: DateTime.utc(2026, 3, 1),
        endedAt: DateTime.utc(2026, 3, 1, 2),
        repBasedSets: const [(weightKg: 100, reps: 5)],
      );
      final earlier = _session(
        id: 's-a',
        startedAt: DateTime.utc(2026, 3, 1),
        endedAt: DateTime.utc(2026, 3, 1, 1),
        repBasedSets: const [(weightKg: 90, reps: 5)],
      );

      // Same startedAt; pass in reverse-id order to prove the id tiebreak.
      final series = ExerciseProgressAggregator.compute(
        libraryExerciseId: benchLibraryId,
        sessions: [later, earlier],
      );

      expect(series.points, hasLength(2));
      // 's-a' sorts before 's-b' on the id tiebreak.
      expect(series.points[0].topSetWeightKg, 90);
      expect(series.points[1].topSetWeightKg, 100);
    });
  });
}

// ---------------------------------------------------------------------------
// Builders — deterministic completed sessions whose snapshot carries one
// `repBased` exercise linked to [exerciseLibraryId].
// ---------------------------------------------------------------------------

Session _session({
  required String id,
  required DateTime startedAt,
  required DateTime? endedAt,
  String programId = 'prog',
  String workoutDayName = 'Day',
  String exerciseLibraryId = benchLibraryId,
  required List<({double weightKg, int reps})> repBasedSets,
}) {
  const plannedId = 'planned-bench';
  final exercise = _plannedExercise(
    id: plannedId,
    libraryExerciseId: exerciseLibraryId,
    measurementType: const MeasurementType.repBased(),
  );
  final snapshot = _snapshot(
    programId: programId,
    name: workoutDayName,
    exercises: [exercise],
  );

  return Session(
    id: id,
    workoutDayId: snapshot.workoutDay.id,
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: '$id-se',
        sessionId: id,
        position: 0,
        plannedExerciseIdInSnapshot: plannedId,
        state: const ExerciseState.completed(),
        executedSets: [
          for (var i = 0; i < repBasedSets.length; i++)
            ExecutedSet(
              id: '$id-set-$i',
              sessionExerciseId: '$id-se',
              position: i,
              measurementType: const MeasurementType.repBased(),
              actualValues: ActualSetValues.repBased(
                weightKg: repBasedSets[i].weightKg,
                reps: repBasedSets[i].reps,
              ),
              completedAt: startedAt,
              createdAt: startedAt,
              updatedAt: startedAt,
              schemaVersion: 1,
            ),
        ],
        createdAt: startedAt,
        updatedAt: startedAt,
        schemaVersion: 1,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: startedAt,
    updatedAt: startedAt,
    schemaVersion: 1,
  );
}

/// A completed session whose linked exercise is `timeBased` (weighted carry),
/// used to prove the aggregator excludes non-`repBased` exercises.
Session _timeBasedSession({
  required String id,
  required DateTime startedAt,
  required DateTime endedAt,
}) {
  const plannedId = 'planned-plank';
  final exercise = _plannedExercise(
    id: plannedId,
    libraryExerciseId: benchLibraryId,
    measurementType: const MeasurementType.timeBased(),
  );
  final snapshot = _snapshot(
    programId: 'prog',
    name: 'Day',
    exercises: [exercise],
  );

  return Session(
    id: id,
    workoutDayId: snapshot.workoutDay.id,
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: '$id-se',
        sessionId: id,
        position: 0,
        plannedExerciseIdInSnapshot: plannedId,
        state: const ExerciseState.completed(),
        executedSets: [
          ExecutedSet(
            id: '$id-set-0',
            sessionExerciseId: '$id-se',
            position: 0,
            measurementType: const MeasurementType.timeBased(),
            actualValues: const ActualSetValues.timeBased(
              durationSeconds: 60,
              weightKg: 20,
            ),
            completedAt: startedAt,
            createdAt: startedAt,
            updatedAt: startedAt,
            schemaVersion: 1,
          ),
        ],
        createdAt: startedAt,
        updatedAt: startedAt,
        schemaVersion: 1,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: startedAt,
    updatedAt: startedAt,
    schemaVersion: 1,
  );
}

/// A completed session whose linked exercise is `bodyweight`, used to prove the
/// aggregator excludes non-`repBased` exercises.
Session _bodyweightSession({
  required String id,
  required DateTime startedAt,
  required DateTime endedAt,
}) {
  const plannedId = 'planned-pullup';
  final exercise = _plannedExercise(
    id: plannedId,
    libraryExerciseId: benchLibraryId,
    measurementType: const MeasurementType.bodyweight(),
  );
  final snapshot = _snapshot(
    programId: 'prog',
    name: 'Day',
    exercises: [exercise],
  );

  return Session(
    id: id,
    workoutDayId: snapshot.workoutDay.id,
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: '$id-se',
        sessionId: id,
        position: 0,
        plannedExerciseIdInSnapshot: plannedId,
        state: const ExerciseState.completed(),
        executedSets: [
          ExecutedSet(
            id: '$id-set-0',
            sessionExerciseId: '$id-se',
            position: 0,
            measurementType: const MeasurementType.bodyweight(),
            actualValues: const ActualSetValues.bodyweight(reps: 10),
            completedAt: startedAt,
            createdAt: startedAt,
            updatedAt: startedAt,
            schemaVersion: 1,
          ),
        ],
        createdAt: startedAt,
        updatedAt: startedAt,
        schemaVersion: 1,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: startedAt,
    updatedAt: startedAt,
    schemaVersion: 1,
  );
}

Exercise _plannedExercise({
  required String id,
  required String? libraryExerciseId,
  required MeasurementType measurementType,
}) {
  return Exercise(
    id: id,
    exerciseGroupId: '$id-g',
    position: 0,
    name: 'Bench Press',
    measurementType: measurementType,
    metadata: ExerciseMetadata.empty,
    libraryExerciseId: libraryExerciseId,
    sets: const [],
    createdAt: _t0,
    updatedAt: _t0,
    schemaVersion: 1,
  );
}

SessionSnapshot _snapshot({
  required String programId,
  required String name,
  required List<Exercise> exercises,
}) {
  final groups = [
    for (var i = 0; i < exercises.length; i++)
      ExerciseGroup(
        id: '${exercises[i].id}-g',
        workoutDayId: 'wd',
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercises[i]],
        createdAt: _t0,
        updatedAt: _t0,
        schemaVersion: 1,
      ),
  ];
  final workoutDay = WorkoutDay(
    id: 'wd',
    programId: programId,
    name: name,
    exerciseGroups: groups,
    createdAt: _t0,
    updatedAt: _t0,
    schemaVersion: 1,
  );
  return SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: _t0,
    schemaVersion: 1,
  );
}
