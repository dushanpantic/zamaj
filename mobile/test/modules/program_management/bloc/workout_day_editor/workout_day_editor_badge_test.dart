import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';

const _benchLibraryId = '11111111-1111-4111-8111-111111111111';
const _squatLibraryId = '22222222-2222-4222-8222-222222222222';
final _now = DateTime.utc(2026, 1, 1);

void main() {
  group('WorkoutDayEditorBloc attention badges', () {
    test('badges a capped, linked, main-group exercise; excludes warmup and '
        'unlinked (AC13, AC16, AC17)', () async {
      final day = _day([
        _group(
          id: 'g-main',
          role: ExerciseGroupRole.main,
          exercises: [_exercise(id: 'main-linked', libraryId: _benchLibraryId)],
        ),
        _group(
          id: 'g-warmup',
          role: ExerciseGroupRole.warmup,
          exercises: [_exercise(id: 'warm-linked', libraryId: _squatLibraryId)],
        ),
        _group(
          id: 'g-unlinked',
          role: ExerciseGroupRole.main,
          exercises: [_exercise(id: 'main-unlinked', libraryId: null)],
        ),
      ]);
      final sessions = [
        _cappedSession(id: 'bench', libraryId: _benchLibraryId),
        _cappedSession(id: 'squat', libraryId: _squatLibraryId),
      ];

      final badged = await _badges(day: day, sessions: sessions);

      expect(badged, {'main-linked'});
    });

    test('does not badge once the plan has advanced past the capped session '
        '(AC15)', () async {
      final day = _day([
        _group(
          id: 'g-main',
          role: ExerciseGroupRole.main,
          exercises: [
            _exercise(
              id: 'main-linked',
              libraryId: _benchLibraryId,
              target: RepTarget.fixed(reps: 12),
            ),
          ],
        ),
      ]);
      // The capped session was logged at the older 10-12 range prescription.
      final sessions = [
        _cappedSession(
          id: 'bench',
          libraryId: _benchLibraryId,
          target: RepTarget.range(minReps: 10, maxReps: 12),
        ),
      ];

      final badged = await _badges(day: day, sessions: sessions);

      expect(badged, isEmpty);
    });

    test('a capped session at a different load elsewhere does not badge '
        '(AC18)', () async {
      final day = _day([
        _group(
          id: 'g-main',
          role: ExerciseGroupRole.main,
          exercises: [
            _exercise(
              id: 'main-linked',
              libraryId: _benchLibraryId,
              weight: 80,
            ),
          ],
        ),
      ]);
      final sessions = [
        _cappedSession(
          id: 'bench-light',
          libraryId: _benchLibraryId,
          weight: 60,
        ),
      ];

      final badged = await _badges(day: day, sessions: sessions);

      expect(badged, isEmpty);
    });
  });
}

Future<Set<String>> _badges({
  required WorkoutDay day,
  required List<Session> sessions,
}) async {
  final bloc = WorkoutDayEditorBloc(
    programRepository: _FakeProgramRepository(day),
    sessionRepository: _FakeSessionRepository(sessions),
  );
  bloc.add(WorkoutDayEditorOpened(workoutDayId: day.id));
  await pumpEventQueue();
  return (bloc.state as WorkoutDayEditorEditing).badgedExerciseIds;
}

WorkoutDay _day(List<ExerciseGroup> groups) => WorkoutDay(
  id: 'wd',
  programId: 'prog',
  name: 'Push',
  exerciseGroups: groups,
  createdAt: _now,
  updatedAt: _now,
  schemaVersion: SchemaVersions.domain,
);

ExerciseGroup _group({
  required String id,
  required ExerciseGroupRole role,
  required List<Exercise> exercises,
}) => ExerciseGroup(
  id: id,
  workoutDayId: 'wd',
  position: 0,
  kind: exercises.length == 1
      ? const ExerciseGroupKind.single()
      : const ExerciseGroupKind.superset(),
  exercises: exercises,
  role: role,
  createdAt: _now,
  updatedAt: _now,
  schemaVersion: SchemaVersions.domain,
);

Exercise _exercise({
  required String id,
  required String? libraryId,
  double weight = 80,
  RepTarget? target,
  int setCount = 3,
}) {
  final repTarget = target ?? RepTarget.range(minReps: 10, maxReps: 12);
  return Exercise(
    id: id,
    exerciseGroupId: 'g-$id',
    position: 0,
    name: id,
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    libraryExerciseId: libraryId,
    sets: [
      for (var i = 0; i < setCount; i++)
        WorkoutSet(
          id: '$id-ws-$i',
          exerciseId: id,
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: weight,
            repTarget: repTarget,
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

/// An ended session of [libraryId], planned 3 sets @ [weight] / [target], all
/// logged at 12 reps — a capped session for a 10-12 (or lower) target.
Session _cappedSession({
  required String id,
  required String libraryId,
  double weight = 80,
  RepTarget? target,
}) {
  final repTarget = target ?? RepTarget.range(minReps: 10, maxReps: 12);
  const plannedId = 'snap-ex';
  final exercise = Exercise(
    id: plannedId,
    exerciseGroupId: '$plannedId-g',
    position: 0,
    name: 'Movement',
    measurementType: const MeasurementType.repBased(),
    metadata: ExerciseMetadata.empty,
    libraryExerciseId: libraryId,
    sets: [
      for (var i = 0; i < 3; i++)
        WorkoutSet(
          id: '$id-ws-$i',
          exerciseId: plannedId,
          position: i,
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: weight,
            repTarget: repTarget,
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
      id: 'wd-$id',
      programId: 'prog-$id',
      name: 'Day',
      exerciseGroups: [
        ExerciseGroup(
          id: '$plannedId-g',
          workoutDayId: 'wd-$id',
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
    workoutDayId: 'wd-$id',
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
              actualValues: ActualSetValues.repBased(
                weightKg: weight,
                reps: 12,
              ),
              completedAt: _now,
              createdAt: _now,
              updatedAt: _now,
              schemaVersion: SchemaVersions.domain,
            ),
        ],
        createdAt: _now,
        updatedAt: _now,
        schemaVersion: SchemaVersions.domain,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: _now,
    endedAt: _now.add(const Duration(hours: 1)),
    createdAt: _now,
    updatedAt: _now,
    schemaVersion: SchemaVersions.domain,
  );
}

class _FakeProgramRepository implements ProgramRepository {
  _FakeProgramRepository(this.day);

  final WorkoutDay day;

  @override
  Future<WorkoutDay?> getWorkoutDay(String workoutDayId) async => day;

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
