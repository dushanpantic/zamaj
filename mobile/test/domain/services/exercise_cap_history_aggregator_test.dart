import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// Canonical UUIDv4-shaped ids (36 chars) — [Exercise] validates that a
/// non-null `libraryExerciseId` is exactly 36 characters.
const benchLibraryId = '11111111-1111-4111-8111-111111111111';
const otherLibraryId = '22222222-2222-4222-8222-222222222222';

final _t0 = DateTime.utc(2024);

// ---------------------------------------------------------------------------
// Planned / actual builders — concise per-set values for the cap predicate.
// ---------------------------------------------------------------------------

PlannedSetValues _repRange(int min, int max, {double weight = 80}) =>
    PlannedSetValues.repBased(
      weightKg: weight,
      repTarget: RepTarget.range(minReps: min, maxReps: max),
    );

PlannedSetValues _repFixed(int reps, {double weight = 80}) =>
    PlannedSetValues.repBased(
      weightKg: weight,
      repTarget: RepTarget.fixed(reps: reps),
    );

PlannedSetValues _bwRange(int min, int max) => PlannedSetValues.bodyweight(
  repTarget: RepTarget.range(minReps: min, maxReps: max),
);

ActualSetValues _actReps(int reps, {double weight = 80}) =>
    ActualSetValues.repBased(weightKg: weight, reps: reps);

ActualSetValues _actBodyweight(int reps) =>
    ActualSetValues.bodyweight(reps: reps);

PlannedSetValues _time(int seconds) =>
    PlannedSetValues.timeBased(durationSeconds: seconds);

ActualSetValues _actTime(int seconds) =>
    ActualSetValues.timeBased(durationSeconds: seconds);

void main() {
  group('ExerciseCapHistoryAggregator.isCapped — rep-based & bodyweight', () {
    test('rep-range caps when every working set reaches the top (AC1)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [
            _repRange(10, 12),
            _repRange(10, 12),
            _repRange(10, 12),
          ],
          actualSets: [_actReps(12), _actReps(12), _actReps(12)],
        ),
        isTrue,
      );
    });

    test('rep-range does not cap when one set falls short (AC1)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [
            _repRange(10, 12),
            _repRange(10, 12),
            _repRange(10, 12),
          ],
          actualSets: [_actReps(12), _actReps(12), _actReps(11)],
        ),
        isFalse,
      );
    });

    test('fixed target caps when every set meets the target (AC2)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repFixed(12), _repFixed(12), _repFixed(12)],
          actualSets: [_actReps(12), _actReps(12), _actReps(12)],
        ),
        isTrue,
      );
    });

    test('fixed target does not cap when one set falls short (AC2)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repFixed(12), _repFixed(12), _repFixed(12)],
          actualSets: [_actReps(12), _actReps(12), _actReps(11)],
        ),
        isFalse,
      );
    });

    test('reps exceeding the ceiling still cap (AC4)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [
            _repRange(10, 12),
            _repRange(10, 12),
            _repRange(10, 12),
          ],
          actualSets: [_actReps(13), _actReps(12), _actReps(14)],
        ),
        isTrue,
      );
    });

    test('bodyweight uses the rep-ceiling rule and caps (AC5)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_bwRange(8, 10), _bwRange(8, 10), _bwRange(8, 10)],
          actualSets: [
            _actBodyweight(10),
            _actBodyweight(10),
            _actBodyweight(10),
          ],
        ),
        isTrue,
      );
    });

    test('bodyweight does not cap when one set falls short (AC5)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_bwRange(8, 10), _bwRange(8, 10), _bwRange(8, 10)],
          actualSets: [
            _actBodyweight(10),
            _actBodyweight(9),
            _actBodyweight(10),
          ],
        ),
        isFalse,
      );
    });

    test('descending vary-by-set (drop set) generally does not cap (AC6)', () {
      // Planned 8 / 6 / 4 fixed; logged 8 / 5 / 4 — the middle set misses its
      // own ceiling of 6.
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_repFixed(8), _repFixed(6), _repFixed(4)],
          actualSets: [_actReps(8), _actReps(5), _actReps(4)],
        ),
        isFalse,
      );
    });

    test(
      'ascending pyramid caps when every set meets its own ceiling (AC6)',
      () {
        // Planned 8-10 / 6-8 / 4-6; logged 10 / 8 / 6 — each hits its own top.
        expect(
          ExerciseCapHistoryAggregator.isCapped(
            plannedSets: [_repRange(8, 10), _repRange(6, 8), _repRange(4, 6)],
            actualSets: [_actReps(10), _actReps(8), _actReps(6)],
          ),
          isTrue,
        );
      },
    );

    test(
      'an unfinished session (fewer sets logged than planned) does not cap',
      () {
        expect(
          ExerciseCapHistoryAggregator.isCapped(
            plannedSets: [
              _repRange(10, 12),
              _repRange(10, 12),
              _repRange(10, 12),
            ],
            actualSets: [_actReps(12), _actReps(12)],
          ),
          isFalse,
        );
      },
    );
  });

  group('ExerciseCapHistoryAggregator.isCapped — time-based', () {
    test('caps when every hold meets the planned duration (AC3)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_time(45), _time(45), _time(45)],
          actualSets: [_actTime(45), _actTime(50), _actTime(45)],
        ),
        isTrue,
      );
    });

    test('does not cap when one hold falls short of the duration (AC3)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_time(45), _time(45), _time(45)],
          actualSets: [_actTime(45), _actTime(40), _actTime(45)],
        ),
        isFalse,
      );
    });

    test('a duration exceeding the planned hold still caps (AC4)', () {
      expect(
        ExerciseCapHistoryAggregator.isCapped(
          plannedSets: [_time(45), _time(45), _time(45)],
          actualSets: [_actTime(50), _actTime(60), _actTime(45)],
        ),
        isTrue,
      );
    });
  });

  group('ExerciseCapHistoryAggregator.computeHistory', () {
    test('returns the five most recent ended sessions, newest first, across '
        'programs (AC7, AC8)', () {
      // Seven ended sessions, alternating between two programs, with strictly
      // increasing dates. Passed oldest-first to prove the newest-first sort.
      final sessions = [
        for (var i = 0; i < 7; i++)
          _repSession(
            id: 's$i',
            startedAt: DateTime.utc(2026, 1, 1 + i),
            programId: i.isEven ? 'A' : 'B',
            actualReps: const [12, 12, 12],
          ),
      ];

      final history = ExerciseCapHistoryAggregator.computeHistory(
        libraryExerciseId: benchLibraryId,
        sessions: sessions,
      );

      expect(history.entries, hasLength(5));
      // Newest first: dates strictly descending.
      for (var i = 0; i < history.entries.length - 1; i++) {
        expect(
          history.entries[i].date.isAfter(history.entries[i + 1].date),
          isTrue,
        );
      }
      expect(history.entries.first.date, DateTime.utc(2026, 1, 7));
      // Both programs contribute to the window.
      final programs = history.entries.map((e) => e.programId).toSet();
      expect(programs, containsAll(<String>['A', 'B']));
    });

    test('an in-progress (not ended) session is excluded', () {
      final ended = _repSession(
        id: 'done',
        startedAt: DateTime.utc(2026, 3, 1),
        actualReps: const [12, 12, 12],
      );
      final open = _repSession(
        id: 'open',
        startedAt: DateTime.utc(2026, 3, 2),
        ended: false,
        actualReps: const [12, 12, 12],
      );

      final history = ExerciseCapHistoryAggregator.computeHistory(
        libraryExerciseId: benchLibraryId,
        sessions: [open, ended],
      );

      expect(history.entries, hasLength(1));
      expect(history.entries.single.date, DateTime.utc(2026, 3, 1));
    });

    test('a movement with no ended sessions yields empty history (AC10)', () {
      final unrelated = _repSession(
        id: 'other',
        startedAt: DateTime.utc(2026, 3, 1),
        libraryExerciseId: otherLibraryId,
        actualReps: const [12, 12, 12],
      );

      final history = ExerciseCapHistoryAggregator.computeHistory(
        libraryExerciseId: benchLibraryId,
        sessions: [unrelated],
      );

      expect(history.isEmpty, isTrue);
    });

    test(
      'each entry carries per-set planned/actual values and the cap flag',
      () {
        final capped = _repSession(
          id: 'capped',
          startedAt: DateTime.utc(2026, 3, 2),
          actualReps: const [12, 12, 12],
        );
        final offDay = _repSession(
          id: 'off',
          startedAt: DateTime.utc(2026, 3, 1),
          actualReps: const [12, 12, 11],
        );

        final history = ExerciseCapHistoryAggregator.computeHistory(
          libraryExerciseId: benchLibraryId,
          sessions: [capped, offDay],
        );

        expect(history.entries, hasLength(2));
        final newest = history.entries.first;
        expect(newest.plannedSets, hasLength(3));
        expect(newest.actualSets, hasLength(3));
        expect(newest.isCapped, isTrue);
        expect(history.entries[1].isCapped, isFalse);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Session fixtures — ended rep-based sessions whose snapshot carries one
// exercise (linked to [libraryExerciseId]) with [plannedSetCount] planned sets
// at [weightKg] / [target], and one logged set per entry in [actualReps].
// ---------------------------------------------------------------------------

Session _repSession({
  required String id,
  required DateTime startedAt,
  bool ended = true,
  String programId = 'prog',
  String dayName = 'Day',
  String? libraryExerciseId = benchLibraryId,
  double weightKg = 80,
  RepTarget? target,
  required List<int> actualReps,
  int? plannedSetCount,
}) {
  final repTarget = target ?? RepTarget.range(minReps: 10, maxReps: 12);
  final setCount = plannedSetCount ?? actualReps.length;
  final resolvedEndedAt = ended
      ? startedAt.add(const Duration(hours: 1))
      : null;

  const plannedId = 'planned-ex';
  final exercise = Exercise(
    id: plannedId,
    exerciseGroupId: '$plannedId-g',
    position: 0,
    name: 'Bench Press',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    libraryExerciseId: libraryExerciseId,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: '$id-ws-$i',
          exerciseId: plannedId,
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: weightKg,
            repTarget: repTarget,
          ),
          createdAt: _t0,
          updatedAt: _t0,
          schemaVersion: 1,
        ),
    ],
    createdAt: _t0,
    updatedAt: _t0,
    schemaVersion: 1,
  );

  final snapshot = _snapshotFor(
    exercise: exercise,
    programId: programId,
    dayName: dayName,
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
          for (var i = 0; i < actualReps.length; i++)
            ExecutedSet(
              id: '$id-set-$i',
              sessionExerciseId: '$id-se',
              position: i,
              measurementType: const MeasurementType.repBased(),
              actualValues: ActualSetValues.repBased(
                weightKg: weightKg,
                reps: actualReps[i],
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
    endedAt: resolvedEndedAt,
    createdAt: startedAt,
    updatedAt: startedAt,
    schemaVersion: 1,
  );
}

SessionSnapshot _snapshotFor({
  required Exercise exercise,
  required String programId,
  required String dayName,
}) {
  final workoutDay = WorkoutDay(
    id: 'wd',
    programId: programId,
    name: dayName,
    exerciseGroups: [
      ExerciseGroup(
        id: '${exercise.id}-g',
        workoutDayId: 'wd',
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercise],
        createdAt: _t0,
        updatedAt: _t0,
        schemaVersion: 1,
      ),
    ],
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
