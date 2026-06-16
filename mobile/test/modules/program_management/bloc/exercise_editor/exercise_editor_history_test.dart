import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';

const _benchLibraryId = '11111111-1111-4111-8111-111111111111';
final _now = DateTime.utc(2026, 1, 1);

void main() {
  group('ExerciseEditorBloc recent set-history', () {
    test('an unlinked exercise exposes the link nudge (AC11)', () async {
      final bloc = await _opened(exercise: _exercise(libraryId: null));

      final view = _editing(bloc).recentHistory;
      expect(view, isA<RecentHistoryUnlinked>());
    });

    test('a linked exercise with no sessions exposes empty history '
        '(AC10)', () async {
      final bloc = await _opened(
        exercise: _exercise(libraryId: _benchLibraryId),
      );

      final view = _editing(bloc).recentHistory;
      expect(view, isA<RecentHistoryAvailable>());
      expect((view as RecentHistoryAvailable).history.isEmpty, isTrue);
    });

    test('a linked exercise surfaces its recent capped session '
        '(AC7, AC8, AC9)', () async {
      final bloc = await _opened(
        exercise: _exercise(libraryId: _benchLibraryId),
        sessions: [
          _cappedSession(id: 's1', startedAt: DateTime.utc(2026, 3, 1)),
        ],
      );

      final view = _editing(bloc).recentHistory as RecentHistoryAvailable;
      expect(view.history.entries, hasLength(1));
      expect(view.history.entries.single.isCapped, isTrue);
    });
  });
}

ExerciseEditorEditing _editing(ExerciseEditorBloc bloc) =>
    bloc.state as ExerciseEditorEditing;

Future<ExerciseEditorBloc> _opened({
  required Exercise exercise,
  List<Session> sessions = const [],
}) async {
  final bloc = ExerciseEditorBloc(
    programRepository: _FakeProgramRepository(exercise),
    sessionRepository: _FakeSessionRepository(sessions),
    externalLinkLauncher: _FakeLinkLauncher(),
  );
  bloc.add(const ExerciseEditorOpened(exerciseId: 'ex1'));
  await pumpEventQueue();
  return bloc;
}

Exercise _exercise({required String? libraryId, int setCount = 3}) {
  return Exercise(
    id: 'ex1',
    exerciseGroupId: 'g1',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    plannedRestSeconds: 180,
    libraryExerciseId: libraryId,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: 'set$i',
          exerciseId: 'ex1',
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 80,
            repTarget: RepTarget.range(minReps: 10, maxReps: 12),
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

/// An ended session of the bench movement, planned 3×10-12 @ 80, logged
/// 12·12·12 — a capped session.
Session _cappedSession({required String id, required DateTime startedAt}) {
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
            repTarget: RepTarget.range(minReps: 10, maxReps: 12),
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
                reps: 12,
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

class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository(this.exercise);

  final Exercise exercise;

  @override
  Future<Exercise?> getExercise(String exerciseId) async => exercise;

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
