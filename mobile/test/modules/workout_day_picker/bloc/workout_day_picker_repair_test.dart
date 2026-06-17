// TEMP: snapshot link repair — remove after one-time run
//
// Hand-written bloc coverage (no bloc_test, per project convention) for the
// temporary repair orchestration on the workout-day picker: preview computes
// counts without writing, dismiss is a no-op, apply persists the cached
// rewrites and reports a result, and the run is idempotent + program-scoped +
// resilient to a deleted day.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

final _t = DateTime.utc(2024, 6, 1, 12);
final _clock = Clock.fixed(_t);

const _programA = '33333333-3333-4333-8333-333333333333';
const _programB = '44444444-4444-4444-8444-444444444444';
const _libCurrent = '11111111-1111-4111-8111-111111111111';
const _libOther = '22222222-2222-4222-8222-222222222222';

Exercise _ex({required String id, required String name, String? link}) =>
    Exercise(
      id: id,
      exerciseGroupId: 'g1',
      position: 0,
      name: name,
      measurementType: const MeasurementType.repBased(),
      metadata: ExerciseMetadata.empty,
      libraryExerciseId: link,
      sets: const [],
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    );

WorkoutDay _day({
  required String id,
  required String programId,
  required Exercise exercise,
}) => WorkoutDay(
  id: id,
  programId: programId,
  name: 'Day',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g1',
      workoutDayId: id,
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

Program _program(String id, List<String> dayIds) => Program(
  id: id,
  name: 'P',
  workoutDayIds: dayIds,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

Session _session({
  required String id,
  required WorkoutDay snapshotDay,
  required bool ended,
}) {
  return Session(
    id: id,
    workoutDayId: snapshotDay.id,
    snapshot: SessionSnapshot.capture(
      workoutDay: snapshotDay,
      capturedAt: _t,
      schemaVersion: 1,
    ),
    sessionExercises: const [],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    endedAt: ended ? _t.add(const Duration(hours: 1)) : null,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

Session _endedSession({required String id, required WorkoutDay snapshotDay}) =>
    _session(id: id, snapshotDay: snapshotDay, ended: true);

class _FakeProgramRepository implements ProgramRepository {
  final Map<String, Program> programs = {};
  final Map<String, List<WorkoutDay>> daysByProgram = {};

  void seed(Program program, List<WorkoutDay> days) {
    programs[program.id] = program;
    daysByProgram[program.id] = days;
  }

  @override
  Future<Program?> getProgram(String programId) async => programs[programId];

  @override
  Future<List<WorkoutDay>> listWorkoutDaysForProgram(String programId) async =>
      daysByProgram[programId] ?? const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every snapshot overwrite while still performing it, so tests can
/// assert both "no write happened" and "these sessions were rewritten".
class _RecordingSessionRepository extends FakeSessionRepository {
  _RecordingSessionRepository({required super.clock});

  final List<String> overwrittenSessionIds = [];

  @override
  Future<void> overwriteSnapshotWorkoutDay({
    required String sessionId,
    required WorkoutDay workoutDay,
  }) async {
    overwrittenSessionIds.add(sessionId);
    await super.overwriteSnapshotWorkoutDay(
      sessionId: sessionId,
      workoutDay: workoutDay,
    );
  }
}

WorkoutDayPickerBloc _buildBloc(
  _FakeProgramRepository programRepo,
  _RecordingSessionRepository sessionRepo,
) => WorkoutDayPickerBloc(
  programRepository: programRepo,
  sessionRepository: sessionRepo,
  sessionFlowEngine: SessionFlowEngine(repository: sessionRepo),
  clock: _clock,
  initialProgramName: 'P',
);

/// Drives [bloc] into its loaded state for [programId].
Future<WorkoutDayPickerLoaded> _load(
  WorkoutDayPickerBloc bloc,
  String programId,
) async {
  bloc.add(WorkoutDayPickerOpened(programId: programId, programName: 'P'));
  return (await bloc.stream
          .firstWhere((s) => s is WorkoutDayPickerLoaded)
          .timeout(const Duration(seconds: 5)))
      as WorkoutDayPickerLoaded;
}

Future<WorkoutDayPickerLoaded> _nextLoaded(
  WorkoutDayPickerBloc bloc,
  bool Function(WorkoutDayPickerLoaded) predicate,
) async {
  return (await bloc.stream
          .firstWhere((s) => s is WorkoutDayPickerLoaded && predicate(s))
          .timeout(const Duration(seconds: 5)))
      as WorkoutDayPickerLoaded;
}

/// Previews then confirms the repair, returning the loaded state once a result
/// summary is present.
Future<WorkoutDayPickerLoaded> _applyRepair(WorkoutDayPickerBloc bloc) async {
  bloc.add(const WorkoutDayPickerRepairPreviewRequested());
  await _nextLoaded(bloc, (s) => s.repairPreview != null);
  bloc.add(const WorkoutDayPickerRepairConfirmed());
  return _nextLoaded(bloc, (s) => s.repairResult != null);
}

void main() {
  group('WorkoutDayPickerBloc repair preview', () {
    test('preview reports counts without writing any snapshot', () async {
      final programRepo = _FakeProgramRepository()
        ..seed(_program(_programA, ['wd1']), [
          _day(
            id: 'wd1',
            programId: _programA,
            exercise: _ex(id: 'ex-bench', name: 'Bench', link: _libCurrent),
          ),
        ]);
      final sessionRepo = _RecordingSessionRepository(clock: _clock)
        ..seedSession(
          _endedSession(
            id: 's1',
            snapshotDay: _day(
              id: 'wd1',
              programId: _programA,
              exercise: _ex(id: 'ex-bench', name: 'Bench'),
            ),
          ),
        );
      final bloc = _buildBloc(programRepo, sessionRepo);
      addTearDown(bloc.close);

      await _load(bloc, _programA);
      bloc.add(const WorkoutDayPickerRepairPreviewRequested());
      final previewed = await _nextLoaded(bloc, (s) => s.repairPreview != null);

      final preview = previewed.repairPreview!;
      expect(preview.sessionsScanned, 1);
      expect(preview.sessionsToChange, 1);
      expect(preview.exercisesToReLink, 1);
      expect(preview.unmatched, 0);
      expect(preview.currentUnlinked, 0);
      expect(preview.daysMissing, 0);

      // No snapshot was written, and the stored link is still null.
      expect(sessionRepo.overwrittenSessionIds, isEmpty);
      final stored = await sessionRepo.getSession('s1');
      expect(
        stored!
            .snapshot
            .workoutDay
            .exerciseGroups
            .single
            .exercises
            .single
            .libraryExerciseId,
        isNull,
      );
    });

    test('dismiss clears the preview and writes nothing', () async {
      final programRepo = _FakeProgramRepository()
        ..seed(_program(_programA, ['wd1']), [
          _day(
            id: 'wd1',
            programId: _programA,
            exercise: _ex(id: 'ex-bench', name: 'Bench', link: _libCurrent),
          ),
        ]);
      final sessionRepo = _RecordingSessionRepository(clock: _clock)
        ..seedSession(
          _endedSession(
            id: 's1',
            snapshotDay: _day(
              id: 'wd1',
              programId: _programA,
              exercise: _ex(id: 'ex-bench', name: 'Bench'),
            ),
          ),
        );
      final bloc = _buildBloc(programRepo, sessionRepo);
      addTearDown(bloc.close);

      await _load(bloc, _programA);
      bloc.add(const WorkoutDayPickerRepairPreviewRequested());
      await _nextLoaded(bloc, (s) => s.repairPreview != null);

      bloc.add(const WorkoutDayPickerRepairDismissed());
      final dismissed = await _nextLoaded(bloc, (s) => s.repairPreview == null);

      expect(dismissed.repairPreview, isNull);
      expect(sessionRepo.overwrittenSessionIds, isEmpty);
    });
  });

  group('WorkoutDayPickerBloc repair apply', () {
    String? storedLink(FakeSessionRepository repo, Session? session) => session
        ?.snapshot
        .workoutDay
        .exerciseGroups
        .single
        .exercises
        .single
        .libraryExerciseId;

    test(
      'apply rewrites the matched snapshot and reports the result',
      () async {
        final programRepo = _FakeProgramRepository()
          ..seed(_program(_programA, ['wd1']), [
            _day(
              id: 'wd1',
              programId: _programA,
              exercise: _ex(id: 'ex-bench', name: 'Bench', link: _libCurrent),
            ),
          ]);
        final sessionRepo = _RecordingSessionRepository(clock: _clock)
          ..seedSession(
            _endedSession(
              id: 's1',
              snapshotDay: _day(
                id: 'wd1',
                programId: _programA,
                exercise: _ex(id: 'ex-bench', name: 'Bench'),
              ),
            ),
          );
        final bloc = _buildBloc(programRepo, sessionRepo);
        addTearDown(bloc.close);

        await _load(bloc, _programA);
        final applied = await _applyRepair(bloc);

        final result = applied.repairResult!;
        expect(result.sessionsChanged, 1);
        expect(result.exercisesReLinked, 1);
        expect(applied.repairPreview, isNull);

        expect(sessionRepo.overwrittenSessionIds, ['s1']);
        expect(
          storedLink(sessionRepo, await sessionRepo.getSession('s1')),
          _libCurrent,
        );
      },
    );

    test('re-running after a completed repair reports zero', () async {
      final programRepo = _FakeProgramRepository()
        ..seed(_program(_programA, ['wd1']), [
          _day(
            id: 'wd1',
            programId: _programA,
            exercise: _ex(id: 'ex-bench', name: 'Bench', link: _libCurrent),
          ),
        ]);
      final sessionRepo = _RecordingSessionRepository(clock: _clock)
        ..seedSession(
          _endedSession(
            id: 's1',
            snapshotDay: _day(
              id: 'wd1',
              programId: _programA,
              exercise: _ex(id: 'ex-bench', name: 'Bench'),
            ),
          ),
        );
      final bloc = _buildBloc(programRepo, sessionRepo);
      addTearDown(bloc.close);

      await _load(bloc, _programA);
      await _applyRepair(bloc);
      final second = await _applyRepair(bloc);

      expect(second.repairResult!.exercisesReLinked, 0);
      expect(second.repairResult!.sessionsChanged, 0);
      // Only the first run wrote anything.
      expect(sessionRepo.overwrittenSessionIds, ['s1']);
    });

    test('only the open program is affected', () async {
      final programRepo = _FakeProgramRepository()
        ..seed(_program(_programA, ['wdA']), [
          _day(
            id: 'wdA',
            programId: _programA,
            exercise: _ex(id: 'ex-a', name: 'Bench', link: _libCurrent),
          ),
        ])
        ..seed(_program(_programB, ['wdB']), [
          _day(
            id: 'wdB',
            programId: _programB,
            exercise: _ex(id: 'ex-b', name: 'Squat', link: _libOther),
          ),
        ]);
      final sessionRepo = _RecordingSessionRepository(clock: _clock)
        ..seedSession(
          _endedSession(
            id: 'sA',
            snapshotDay: _day(
              id: 'wdA',
              programId: _programA,
              exercise: _ex(id: 'ex-a', name: 'Bench'),
            ),
          ),
        )
        ..seedSession(
          _endedSession(
            id: 'sB',
            snapshotDay: _day(
              id: 'wdB',
              programId: _programB,
              exercise: _ex(id: 'ex-b', name: 'Squat'),
            ),
          ),
        );
      final bloc = _buildBloc(programRepo, sessionRepo);
      addTearDown(bloc.close);

      await _load(bloc, _programA);
      await _applyRepair(bloc);

      expect(sessionRepo.overwrittenSessionIds, ['sA']);
      expect(
        storedLink(sessionRepo, await sessionRepo.getSession('sB')),
        isNull,
      );
    });

    test('a deleted day is skipped while siblings are repaired', () async {
      final programRepo = _FakeProgramRepository()
        ..seed(_program(_programA, ['wdA']), [
          _day(
            id: 'wdA',
            programId: _programA,
            exercise: _ex(id: 'ex-a', name: 'Bench', link: _libCurrent),
          ),
        ]);
      final sessionRepo = _RecordingSessionRepository(clock: _clock)
        ..seedSession(
          _endedSession(
            id: 'sLive',
            snapshotDay: _day(
              id: 'wdA',
              programId: _programA,
              exercise: _ex(id: 'ex-a', name: 'Bench'),
            ),
          ),
        )
        ..seedSession(
          _endedSession(
            id: 'sDeleted',
            snapshotDay: _day(
              id: 'wd-deleted',
              programId: _programA,
              exercise: _ex(id: 'ex-x', name: 'Gone'),
            ),
          ),
        );
      final bloc = _buildBloc(programRepo, sessionRepo);
      addTearDown(bloc.close);

      await _load(bloc, _programA);
      final applied = await _applyRepair(bloc);

      expect(applied.repairResult!.daysMissing, 1);
      expect(applied.repairResult!.exercisesReLinked, 1);
      expect(sessionRepo.overwrittenSessionIds, ['sLive']);
      expect(
        storedLink(sessionRepo, await sessionRepo.getSession('sLive')),
        _libCurrent,
      );
      expect(
        storedLink(sessionRepo, await sessionRepo.getSession('sDeleted')),
        isNull,
      );
    });

    test('an in-flight session is never counted or rewritten', () async {
      final programRepo = _FakeProgramRepository()
        ..seed(_program(_programA, ['wdA']), [
          _day(
            id: 'wdA',
            programId: _programA,
            exercise: _ex(id: 'ex-a', name: 'Bench', link: _libCurrent),
          ),
        ]);
      final sessionRepo = _RecordingSessionRepository(clock: _clock)
        ..seedSession(
          _endedSession(
            id: 'sEnded',
            snapshotDay: _day(
              id: 'wdA',
              programId: _programA,
              exercise: _ex(id: 'ex-a', name: 'Bench'),
            ),
          ),
        )
        ..seedSession(
          _session(
            id: 'sActive',
            ended: false,
            snapshotDay: _day(
              id: 'wdA',
              programId: _programA,
              exercise: _ex(id: 'ex-a', name: 'Bench'),
            ),
          ),
        );
      final bloc = _buildBloc(programRepo, sessionRepo);
      addTearDown(bloc.close);

      await _load(bloc, _programA);
      bloc.add(const WorkoutDayPickerRepairPreviewRequested());
      final previewed = await _nextLoaded(bloc, (s) => s.repairPreview != null);
      // Only the ended session is scanned.
      expect(previewed.repairPreview!.sessionsScanned, 1);

      bloc.add(const WorkoutDayPickerRepairConfirmed());
      await _nextLoaded(bloc, (s) => s.repairResult != null);

      expect(sessionRepo.overwrittenSessionIds, ['sEnded']);
      expect(
        storedLink(sessionRepo, await sessionRepo.getSession('sActive')),
        isNull,
      );
    });
  });
}
