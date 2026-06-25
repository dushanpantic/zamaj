import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

const _benchLibraryId = '11111111-1111-4111-8111-111111111111';
final _now = DateTime.utc(2026, 1, 1);

void main() {
  group('ExerciseEditorBloc recent-history apply (Step 2.1)', () {
    test('applying replaces the single blank set with the logged sets '
        '(AC1, AC3)', () async {
      final bloc = await _opened(exercise: _linkedExercise());

      bloc.add(
        RecentHistoryEntryApplied(
          entry: _repEntry(const [(100, 5), (100, 5), (100, 4)]),
        ),
      );
      await pumpEventQueue();

      final sets = _editing(bloc).draft.sets;
      expect(sets, hasLength(3));
      expect(sets.map(_reps).toList(), ['5', '5', '4']);
      expect(sets.map(_weight).toList(), ['100.0', '100.0', '100.0']);
    });

    test('more logged sets than the current draft fills all logged sets '
        '(AC3)', () async {
      final bloc = await _opened(exercise: _linkedExercise());

      bloc.add(
        RecentHistoryEntryApplied(
          entry: _repEntry(const [(100, 5), (100, 5), (100, 5), (100, 5)]),
        ),
      );
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, hasLength(4));
    });

    test('fewer logged sets fills only the logged sets (AC3)', () async {
      final bloc = await _opened(exercise: _linkedExercise());

      bloc.add(
        RecentHistoryEntryApplied(entry: _repEntry(const [(100, 5), (100, 5)])),
      );
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, hasLength(2));
    });

    test('a bodyweight entry replaces the blank default with fixed-rep, '
        'weightless sets (AC1, AC2)', () async {
      final bloc = await _opened(exercise: _bodyweightExercise());

      bloc.add(
        RecentHistoryEntryApplied(entry: _bodyweightEntry(const [12, 10])),
      );
      await pumpEventQueue();

      final sets = _editing(bloc).draft.sets;
      expect(sets, hasLength(2));
      expect(sets.map(_reps).toList(), ['12', '10']);
      // Bodyweight sets carry no weight field — the projection reads blank.
      expect(sets.map(_weight).toList(), ['', '']);
    });

    test('an entry that logged no sets is a no-op (AC4)', () async {
      final bloc = await _opened(exercise: _linkedExercise());
      final before = _editing(bloc).draft.sets;

      bloc.add(RecentHistoryEntryApplied(entry: _repEntry(const [])));
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, before);
    });

    test('an entry whose logged sets are a different measurement type is a '
        'whole no-op (AC9)', () async {
      final bloc = await _opened(exercise: _linkedExercise());
      final before = _editing(bloc).draft.sets;

      // Exercise is rep-based; the entry logged time-based holds.
      bloc.add(RecentHistoryEntryApplied(entry: _timeEntry(const [30, 30])));
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, before);
    });

    test('an entry mixing matching and non-matching set types is a whole '
        'no-op, never a partial apply (AC9)', () async {
      final bloc = await _opened(exercise: _linkedExercise()); // rep-based
      final before = _editing(bloc).draft.sets;

      // One rep-based set (matches the exercise) and one time-based set (does
      // not). The whole entry must be rejected — proving the gate rejects the
      // row outright rather than applying only the matching subset. (A real
      // session never logs mixed types, but the guard is value-based.)
      bloc.add(
        RecentHistoryEntryApplied(
          entry: CapHistoryEntry(
            date: DateTime.utc(2026, 3, 1),
            programId: 'prog',
            sourceWorkoutDayName: 'Push',
            plannedSets: const [],
            actualSets: const [
              ActualSetValues.repBased(weightKg: 100, reps: 5),
              ActualSetValues.timeBased(durationSeconds: 30),
            ],
            isCapped: false,
          ),
        ),
      );
      await pumpEventQueue();

      expect(_editing(bloc).draft.sets, before);
    });

    test(
      'applying marks the editor dirty and does not persist (AC6)',
      () async {
        final repo = _RecordingProgramRepository(_linkedExercise());
        final bloc = ExerciseEditorBloc(
          programRepository: repo,
          sessionRepository: _FakeSessionRepository(const []),
          externalLinkLauncher: _FakeLinkLauncher(),
        );
        bloc.add(const ExerciseEditorOpened(exerciseId: 'ex1'));
        await pumpEventQueue();
        expect(bloc.isDirty, isFalse);

        bloc.add(RecentHistoryEntryApplied(entry: _repEntry(const [(100, 5)])));
        await pumpEventQueue();

        expect(bloc.isDirty, isTrue);
        expect(repo.updateCalls, 0);
      },
    );

    test('a deload session is absent from the applyable recent-history rows '
        '(AC8)', () async {
      final bloc = await _opened(
        exercise: _linkedExercise(),
        sessions: [
          _benchSession(id: 'd', startedAt: DateTime.utc(2026, 3, 2)),
          _benchSession(
            id: 'normal',
            startedAt: DateTime.utc(2026, 3, 1),
            isDeload: false,
          ),
          _benchSession(
            id: 'deload',
            startedAt: DateTime.utc(2026, 2, 1),
            isDeload: true,
          ),
        ],
      );

      final history =
          (_editing(bloc).recentHistory as RecentHistoryAvailable).history;
      // Three completed sessions, one of them a deload — only the two
      // non-deload sessions surface as applyable rows.
      expect(history.entries, hasLength(2));
    });
  });

  group('ExerciseEditorBloc recent-history overwrite gate (Step 2.2)', () {
    test('applying over user-entered sets stashes a pending apply and leaves '
        'the sets unchanged (AC5)', () async {
      final bloc = await _opened(exercise: _linkedExercise());
      final setId = _editing(bloc).draft.sets.single.draftId;
      bloc.add(PlannedSetWeightChanged(setDraftId: setId, rawInput: '90'));
      bloc.add(PlannedSetRepsChanged(setDraftId: setId, rawInput: '6'));
      await pumpEventQueue();
      final before = _editing(bloc).draft.sets;
      final entry = _repEntry(const [(100, 5), (100, 5)]);

      bloc.add(RecentHistoryEntryApplied(entry: entry));
      await pumpEventQueue();

      expect(_editing(bloc).pendingHistoryApply, entry);
      expect(_editing(bloc).draft.sets, before);
    });

    test('a set typed then cleared back to blank applies without a prompt '
        '(AC5 boundary)', () async {
      final bloc = await _opened(exercise: _linkedExercise());
      final setId = _editing(bloc).draft.sets.single.draftId;
      bloc.add(PlannedSetWeightChanged(setDraftId: setId, rawInput: '90'));
      bloc.add(PlannedSetWeightChanged(setDraftId: setId, rawInput: ''));
      bloc.add(PlannedSetRepsChanged(setDraftId: setId, rawInput: ''));
      await pumpEventQueue();

      bloc.add(
        RecentHistoryEntryApplied(entry: _repEntry(const [(100, 5), (100, 5)])),
      );
      await pumpEventQueue();

      expect(_editing(bloc).pendingHistoryApply, isNull);
      expect(_editing(bloc).draft.sets, hasLength(2));
    });

    test('confirming the pending apply replaces the sets and clears pending '
        '(AC5)', () async {
      final bloc = await _opened(exercise: _linkedExercise(setCount: 3));
      bloc.add(
        RecentHistoryEntryApplied(entry: _repEntry(const [(100, 5), (100, 5)])),
      );
      await pumpEventQueue();
      expect(_editing(bloc).pendingHistoryApply, isNotNull);

      bloc.add(const RecentHistoryApplyConfirmed());
      await pumpEventQueue();

      expect(_editing(bloc).pendingHistoryApply, isNull);
      expect(_editing(bloc).draft.sets, hasLength(2));
      expect(_editing(bloc).draft.sets.map(_reps).toList(), ['5', '5']);
    });

    test(
      'dismissing the pending apply clears pending and changes nothing',
      () async {
        final bloc = await _opened(exercise: _linkedExercise(setCount: 3));
        final before = _editing(bloc).draft.sets;
        bloc.add(
          RecentHistoryEntryApplied(
            entry: _repEntry(const [(100, 5), (100, 5)]),
          ),
        );
        await pumpEventQueue();

        bloc.add(const RecentHistoryApplyDismissed());
        await pumpEventQueue();

        expect(_editing(bloc).pendingHistoryApply, isNull);
        expect(_editing(bloc).draft.sets, before);
      },
    );

    test(
      'applying a second entry after a prior apply re-gates (AC17)',
      () async {
        final bloc = await _opened(exercise: _linkedExercise());
        bloc.add(RecentHistoryEntryApplied(entry: _repEntry(const [(100, 5)])));
        await pumpEventQueue();
        // First apply replaced the blank default silently; the draft is now
        // non-blank, so a second apply must re-gate.
        expect(_editing(bloc).pendingHistoryApply, isNull);
        expect(_editing(bloc).draft.sets, hasLength(1));

        final second = _repEntry(const [(110, 3), (110, 3)]);
        bloc.add(RecentHistoryEntryApplied(entry: second));
        await pumpEventQueue();

        // The second (not the stale first) entry is what's stashed pending.
        expect(_editing(bloc).pendingHistoryApply, second);
        expect(_editing(bloc).draft.sets, hasLength(1));
      },
    );

    test('confirming after the measurement type changed under the pending '
        'entry is a no-op that clears pending (AC9)', () async {
      final bloc = await _opened(exercise: _linkedExercise(setCount: 3));
      bloc.add(
        RecentHistoryEntryApplied(entry: _repEntry(const [(100, 5), (100, 5)])),
      );
      await pumpEventQueue();
      expect(_editing(bloc).pendingHistoryApply, isNotNull);

      // The exercise becomes time-based while the confirm is pending; the
      // stashed rep-based entry no longer matches, so confirming must reject
      // the whole apply (mapped == null) and just clear pending.
      bloc.add(
        const ExerciseMeasurementTypeChanged(next: MeasurementType.timeBased()),
      );
      await pumpEventQueue();
      final before = _editing(bloc).draft.sets;

      bloc.add(const RecentHistoryApplyConfirmed());
      await pumpEventQueue();

      expect(_editing(bloc).pendingHistoryApply, isNull);
      expect(_editing(bloc).draft.sets, before);
    });
  });
}

ExerciseEditorEditing _editing(ExerciseEditorBloc bloc) =>
    bloc.state as ExerciseEditorEditing;

String _reps(PlannedSetDraft s) => switch (s.values) {
  PlannedSetDraftRepBased(:final repsInput) => repsInput,
  PlannedSetDraftBodyweight(:final repsInput) => repsInput,
  PlannedSetDraftTimeBased() => '',
};

String _weight(PlannedSetDraft s) => switch (s.values) {
  PlannedSetDraftRepBased(:final weightInput) => weightInput,
  PlannedSetDraftTimeBased(:final weightInput) => weightInput,
  PlannedSetDraftBodyweight() => '',
};

CapHistoryEntry _repEntry(List<(double, int)> sets) => CapHistoryEntry(
  date: DateTime.utc(2026, 3, 1),
  programId: 'prog',
  sourceWorkoutDayName: 'Push',
  plannedSets: const [],
  actualSets: [
    for (final (weight, reps) in sets)
      ActualSetValues.repBased(weightKg: weight, reps: reps),
  ],
  isCapped: false,
);

CapHistoryEntry _bodyweightEntry(List<int> reps) => CapHistoryEntry(
  date: DateTime.utc(2026, 3, 1),
  programId: 'prog',
  sourceWorkoutDayName: 'Push',
  plannedSets: const [],
  actualSets: [for (final r in reps) ActualSetValues.bodyweight(reps: r)],
  isCapped: false,
);

CapHistoryEntry _timeEntry(List<int> durations) => CapHistoryEntry(
  date: DateTime.utc(2026, 3, 1),
  programId: 'prog',
  sourceWorkoutDayName: 'Push',
  plannedSets: const [],
  actualSets: [
    for (final seconds in durations)
      ActualSetValues.timeBased(durationSeconds: seconds),
  ],
  isCapped: false,
);

Future<ExerciseEditorBloc> _opened({
  required Exercise exercise,
  List<Session> sessions = const [],
}) async {
  final bloc = ExerciseEditorBloc(
    programRepository: _RecordingProgramRepository(exercise),
    sessionRepository: _FakeSessionRepository(sessions),
    externalLinkLauncher: _FakeLinkLauncher(),
  );
  bloc.add(const ExerciseEditorOpened(exerciseId: 'ex1'));
  await pumpEventQueue();
  return bloc;
}

/// A linked rep-based exercise. With [setCount] 0 the bloc seeds a single blank
/// default set — the starting point for the silent-replace scenarios.
Exercise _linkedExercise({int setCount = 0}) {
  return Exercise(
    id: 'ex1',
    exerciseGroupId: 'g1',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: 180,
    libraryExerciseId: _benchLibraryId,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: 'set$i',
          exerciseId: 'ex1',
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 80,
            repTarget: RepTarget.fixed(reps: 8),
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

/// A linked bodyweight exercise with no persisted sets — the bloc seeds a
/// single blank bodyweight default, the starting point for the bodyweight
/// silent-replace path.
Exercise _bodyweightExercise() {
  return Exercise(
    id: 'ex1',
    exerciseGroupId: 'g1',
    position: 0,
    name: 'Pull-up',
    measurementType: const MeasurementType.bodyweight(),
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: 180,
    libraryExerciseId: _benchLibraryId,
    sets: const [],
    createdAt: _now,
    updatedAt: _now,
    schemaVersion: SchemaVersions.domain,
  );
}

/// An ended session that logged the bench movement 80×8 ×3. [isDeload] flags it
/// as a deload week so the cap-history aggregator excludes it.
Session _benchSession({
  required String id,
  required DateTime startedAt,
  bool isDeload = false,
}) {
  const plannedId = 'planned-bench';
  final exercise = Exercise(
    id: plannedId,
    exerciseGroupId: '$plannedId-g',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    libraryExerciseId: _benchLibraryId,
    sets: [
      for (var i = 0; i < 3; i++)
        WorkoutSet(
          id: '$id-ws-$i',
          exerciseId: plannedId,
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 80,
            repTarget: RepTarget.fixed(reps: 8),
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
  final snapshot = SessionSnapshot.capture(
    workoutDay: WorkoutDay(
      id: 'wd',
      programId: 'prog',
      name: 'Push',
      exerciseGroups: [
        ExerciseGroup(
          id: '$plannedId-g',
          workoutDayId: 'wd',
          position: 0,
          kind: const ExerciseGroupKind.single(),
          exercises: [exercise],
          createdAt: _now,
          updatedAt: _now,
          schemaVersion: SchemaVersions.domain,
        ),
      ],
      createdAt: _now,
      updatedAt: _now,
      schemaVersion: SchemaVersions.domain,
    ),
    capturedAt: _now,
    schemaVersion: SchemaVersions.domain,
  );
  return Session(
    id: id,
    workoutDayId: 'wd',
    snapshot: snapshot,
    isDeload: isDeload,
    sessionExercises: [
      SessionExercise(
        id: '$id-se',
        sessionId: id,
        position: 0,
        plannedExerciseIdInSnapshot: plannedId,
        state: const ExerciseState.completed(),
        executedSets: [
          for (var i = 0; i < 3; i++)
            ExecutedSet(
              id: '$id-set-$i',
              sessionExerciseId: '$id-se',
              position: i,
              measurementType: const MeasurementType.repBased(),
              actualValues: const ActualSetValues.repBased(
                weightKg: 80,
                reps: 8,
              ),
              completedAt: startedAt,
              createdAt: startedAt,
              updatedAt: startedAt,
              schemaVersion: SchemaVersions.domain,
            ),
        ],
        createdAt: startedAt,
        updatedAt: startedAt,
        schemaVersion: SchemaVersions.domain,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: startedAt,
    endedAt: startedAt.add(const Duration(hours: 1)),
    createdAt: startedAt,
    updatedAt: startedAt,
    schemaVersion: SchemaVersions.domain,
  );
}

class _RecordingProgramRepository implements ProgramRepository {
  _RecordingProgramRepository(this.exercise);

  final Exercise exercise;
  int updateCalls = 0;

  @override
  Future<Exercise?> getExercise(String exerciseId) async => exercise;

  @override
  Future<Exercise> updateExercise(Exercise exercise) async {
    updateCalls++;
    return exercise;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSessionRepository implements SessionRepository {
  _FakeSessionRepository(this.completed);

  final List<Session> completed;

  @override
  Future<List<Session>> listCompletedSessions() async => completed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLinkLauncher implements ExternalLinkLauncher {
  @override
  Future<ExternalLinkResult> launch(Uri url) async =>
      const ExternalLinkOpened();
}
