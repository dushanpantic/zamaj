import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('SessionExportFormatter.format', () {
    test('header lists workout day name and ended date', () {
      final session = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12, 18, 30),
        exercises: const [],
      );
      final out = SessionExportFormatter.format(session);
      expect(out.split('\n').take(2).toList(), [
        'Upper A',
        _localIso(DateTime.utc(2026, 5, 12, 18, 30)),
      ]);
      expect(out.contains('(in progress)'), isFalse);
    });

    test('marks in-progress sessions with explicit marker', () {
      final session = _session(
        workoutDayName: 'Upper A',
        endedAt: null,
        exercises: const [],
      );
      final out = SessionExportFormatter.format(session);
      expect(out.contains('(in progress)'), isTrue);
    });

    test('uniform rep-based exercise renders compact Plan + Done', () {
      final session = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: [
          _ExerciseSpec(
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100.0, 8), (100.0, 8), (100.0, 8), (100.0, 8)],
            state: const ExerciseState.completed(),
            actualRep: const [(100.0, 8), (97.5, 8), (95.0, 7), (95.0, 6)],
          ),
        ],
      );
      final out = SessionExportFormatter.format(session);
      expect(out, contains('Bench Press'));
      expect(out, contains('Plan: 100kg 4 × 8'));
      expect(out, contains('Done:'));
      expect(out, contains('100 × 8'));
      expect(out, contains('97.5 × 8'));
      expect(out, contains('95 × 7'));
      expect(out, contains('95 × 6'));
    });

    test('time-based exercise renders durations in seconds, no × prefix', () {
      final session = _session(
        workoutDayName: 'Core',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: [
          _ExerciseSpec(
            name: 'Plank Hold',
            measurementType: const MeasurementType.timeBased(),
            plannedTime: const [30, 30, 30, 30],
            state: const ExerciseState.completed(),
            actualTime: const [35, 30, 28, 25],
          ),
        ],
      );
      final out = SessionExportFormatter.format(session);
      expect(out, contains('Plan: 4 × 30s'));
      expect(out, contains('35s'));
      expect(out, contains('28s'));
      expect(out, isNot(contains('× 35s')));
    });

    test('skipped exercise shows status header and omits Done body', () {
      final session = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: [
          _ExerciseSpec(
            name: 'Curls',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(12.5, 12), (12.5, 12), (12.5, 12)],
            state: const ExerciseState.skipped(),
            actualRep: const [],
          ),
        ],
      );
      final out = SessionExportFormatter.format(session);
      expect(out, contains('Curls  (skipped)'));
      expect(out, contains('Plan: 12.5kg 3 × 12'));
      expect(out, isNot(contains('Done:')));
    });

    test('replaced exercise shows arrow header + sub plan + actuals', () {
      final session = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: [
          _ExerciseSpec(
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100.0, 8), (100.0, 8), (100.0, 8), (100.0, 8)],
            state: ExerciseState.replaced(
              substitute: SubstituteExercise(
                name: 'Cable Fly',
                measurementType: const MeasurementType.repBased(),
                plannedValues: const PlannedSetValues.repBased(
                  weightKg: 20,
                  reps: 12,
                ),
                setCount: 3,
              ),
            ),
            actualRep: const [(20.0, 12), (20.0, 12), (20.0, 10)],
          ),
        ],
      );
      final out = SessionExportFormatter.format(session);
      expect(out, contains('Bench Press → Cable Fly  (replaced)'));
      expect(out, contains('Plan: 100kg 4 × 8'));
      expect(out, contains('Sub plan: 20kg 3 × 12'));
      expect(out, contains('20 × 12'));
      expect(out, contains('20 × 10'));
    });

    test('consecutive exercises sharing a supersetTag render as a block', () {
      final session = _session(
        workoutDayName: 'Pull',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: [
          _ExerciseSpec(
            name: 'Incline DB Press',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(30.0, 10), (30.0, 10), (30.0, 10)],
            state: const ExerciseState.completed(),
            actualRep: const [(30.0, 10), (30.0, 10), (28.0, 9)],
            supersetTag: 'A',
          ),
          _ExerciseSpec(
            name: 'Cable Fly',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(25.0, 12), (25.0, 12), (25.0, 12)],
            state: const ExerciseState.completed(),
            actualRep: const [(25.0, 12), (25.0, 12), (25.0, 11)],
            supersetTag: 'A',
          ),
        ],
      );
      final out = SessionExportFormatter.format(session);
      expect(out, contains('Superset: Incline DB Press + Cable Fly'));
      expect(out, contains('  Incline DB Press'));
      expect(out, contains('  Plan: 30kg 3 × 10'));
      expect(out, contains('  Cable Fly'));
    });

    test('notes section emitted only when notes exist, dashed list', () {
      final base = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: const [],
      );
      expect(SessionExportFormatter.format(base), isNot(contains('Notes:')));

      final withNotes = base.copyWith(
        notes: [
          SessionNote(
            id: 'n1',
            sessionId: base.id,
            body: 'left shoulder pain',
            createdAt: DateTime.utc(2026, 5, 12),
            updatedAt: DateTime.utc(2026, 5, 12),
            schemaVersion: 1,
          ),
          SessionNote(
            id: 'n2',
            sessionId: base.id,
            body: 'felt strong',
            createdAt: DateTime.utc(2026, 5, 12),
            updatedAt: DateTime.utc(2026, 5, 12),
            schemaVersion: 1,
          ),
        ],
      );
      final out = SessionExportFormatter.format(withNotes);
      expect(out, contains('Notes:'));
      expect(out, contains('- left shoulder pain'));
      expect(out, contains('- felt strong'));
    });

    test('extra work section emitted only when populated', () {
      final base = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: const [],
      );
      expect(
        SessionExportFormatter.format(base),
        isNot(contains('Extra work:')),
      );

      final withExtras = base.copyWith(
        extraWork: [
          ExtraWork(
            id: 'x1',
            sessionId: base.id,
            position: 0,
            body: '3 calf sets',
            createdAt: DateTime.utc(2026, 5, 12),
            updatedAt: DateTime.utc(2026, 5, 12),
            schemaVersion: 1,
          ),
        ],
      );
      final out = SessionExportFormatter.format(withExtras);
      expect(out, contains('Extra work:'));
      expect(out, contains('- 3 calf sets'));
    });

    test('output ends without trailing whitespace', () {
      final session = _session(
        workoutDayName: 'Upper A',
        endedAt: DateTime.utc(2026, 5, 12),
        exercises: [
          _ExerciseSpec(
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            plannedRep: const [(100.0, 8)],
            state: const ExerciseState.completed(),
            actualRep: const [(100.0, 8)],
          ),
        ],
      );
      final out = SessionExportFormatter.format(session);
      expect(out.endsWith('\n'), isFalse);
      expect(out.endsWith(' '), isFalse);
    });
  });
}

// -----------------------------------------------------------------------------
// Fixture builders.

class _ExerciseSpec {
  _ExerciseSpec({
    required this.name,
    required this.measurementType,
    required this.state,
    this.plannedRep = const [],
    this.plannedTime = const [],
    this.actualRep = const [],
    this.actualTime = const [],
    this.supersetTag,
  });

  final String name;
  final MeasurementType measurementType;
  final ExerciseState state;
  final List<(double, int)> plannedRep; // (weightKg, reps)
  final List<int> plannedTime;
  final List<(double, int)> actualRep;
  final List<int> actualTime;
  final String? supersetTag;
}

Session _session({
  required String workoutDayName,
  required DateTime? endedAt,
  required List<_ExerciseSpec> exercises,
}) {
  final t = DateTime.utc(2026, 5, 12);
  final workoutDay = WorkoutDay(
    id: 'wd-1',
    programId: 'p-1',
    name: workoutDayName,
    exerciseGroups: [
      for (var i = 0; i < exercises.length; i++)
        ExerciseGroup(
          id: 'g-$i',
          workoutDayId: 'wd-1',
          position: i,
          kind: const ExerciseGroupKind.single(),
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
    startedAt: t,
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
          plannedValues: PlannedSetValues.repBased(weightKg: kg, reps: reps),
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );
    }
  } else {
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
  } else {
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
  }
  return SessionExercise(
    id: 'sx-$idx',
    sessionId: 'session-1',
    position: idx,
    plannedExerciseIdInSnapshot: 'ex-$idx',
    state: spec.state,
    executedSets: executed,
    supersetTag: spec.supersetTag,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}

String _localIso(DateTime utc) {
  final l = utc.toLocal();
  final y = l.year.toString().padLeft(4, '0');
  final m = l.month.toString().padLeft(2, '0');
  final d = l.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
