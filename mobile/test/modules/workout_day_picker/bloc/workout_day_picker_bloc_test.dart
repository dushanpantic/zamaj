import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart'
    show AppDatabase;
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_event.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_state.dart';

final _t = DateTime.utc(2024);

Exercise _exercise(int setCount) => Exercise(
  id: '',
  exerciseGroupId: '',
  position: 0,
  name: 'Squat',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: List.generate(
    setCount,
    (i) => WorkoutSet(
      id: '',
      exerciseId: '',
      position: i,
      measurementType: const MeasurementType.repBased(),
      plannedValues: PlannedSetValues.repBased(
        weightKg: 20,
        repTarget: RepTarget.fixed(reps: 5),
      ),
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    ),
  ),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

class _Harness {
  _Harness(
    this.db,
    this.programRepo,
    this.sessionRepo,
    this.program,
    this.dayId,
  );

  final AppDatabase db;
  final DriftProgramRepository programRepo;
  final DriftSessionRepository sessionRepo;
  final Program program;
  final String dayId;

  WorkoutDayPickerBloc newBloc() => WorkoutDayPickerBloc(
    programRepository: programRepo,
    sessionRepository: sessionRepo,
    sessionFlowEngine: SessionFlowEngine(repository: sessionRepo),
    clock: Clock.fixed(DateTime.utc(2024, 6, 1, 12)),
    initialProgramName: program.name,
  );

  Future<WorkoutDayPickerLoaded> openAndLoad(WorkoutDayPickerBloc bloc) async {
    final loaded = bloc.stream.firstWhere((s) => s is WorkoutDayPickerLoaded);
    bloc.add(
      WorkoutDayPickerOpened(programId: program.id, programName: program.name),
    );
    return await loaded as WorkoutDayPickerLoaded;
  }
}

Future<_Harness> _setup() async {
  final db = AppDatabase(NativeDatabase.memory());
  final programRepo = DriftProgramRepository(db: db);
  final sessionRepo = DriftSessionRepository(
    db: db,
    programRepository: programRepo,
  );
  final program = await programRepo.createProgram(name: 'P');
  final day = await programRepo.createWorkoutDay(
    programId: program.id,
    name: 'Day',
  );
  await programRepo.createExerciseGroup(
    workoutDayId: day.id,
    kind: const ExerciseGroupKind.single(),
    exercises: [_exercise(4)],
  );
  return _Harness(db, programRepo, sessionRepo, program, day.id);
}

void main() {
  group('WorkoutDayPickerBloc deload toggle', () {
    test('the deload selection defaults to off on load', () async {
      final h = await _setup();
      final bloc = h.newBloc();
      addTearDown(bloc.close);
      addTearDown(h.db.close);

      final loaded = await h.openAndLoad(bloc);
      expect(loaded.deloadSelected, isFalse);
    });

    test(
      'a start with deload selected calls the engine with isDeload: true',
      () async {
        final h = await _setup();
        final bloc = h.newBloc();
        addTearDown(bloc.close);
        addTearDown(h.db.close);

        await h.openAndLoad(bloc);
        final toggled = bloc.stream.firstWhere(
          (s) => s is WorkoutDayPickerLoaded && s.deloadSelected,
        );
        bloc.add(const WorkoutDayPickerDeloadToggled(true));
        await toggled;

        final intent = bloc.navigationIntents.first;
        bloc.add(WorkoutDayPickerStartPressed(h.dayId));
        final sessionId = await intent;

        final session = await h.sessionRepo.getSession(sessionId);
        expect(session!.isDeload, isTrue);
        expect(
          session
              .snapshot
              .workoutDay
              .exerciseGroups
              .single
              .exercises
              .single
              .sets
              .length,
          2,
        );
      },
    );

    test('a default start passes isDeload: false', () async {
      final h = await _setup();
      final bloc = h.newBloc();
      addTearDown(bloc.close);
      addTearDown(h.db.close);

      await h.openAndLoad(bloc);

      final intent = bloc.navigationIntents.first;
      bloc.add(WorkoutDayPickerStartPressed(h.dayId));
      final sessionId = await intent;

      final session = await h.sessionRepo.getSession(sessionId);
      expect(session!.isDeload, isFalse);
      expect(
        session
            .snapshot
            .workoutDay
            .exerciseGroups
            .single
            .exercises
            .single
            .sets
            .length,
        4,
      );
    });

    test('an active session still blocks the start', () async {
      final h = await _setup();
      // A session already in flight anywhere blocks new starts.
      await h.sessionRepo.startSession(workoutDayId: h.dayId);

      final bloc = h.newBloc();
      addTearDown(bloc.close);
      addTearDown(h.db.close);

      final loaded = await h.openAndLoad(bloc);
      expect(loaded.activeSession, isNotNull);

      final intents = <String>[];
      final sub = bloc.navigationIntents.listen(intents.add);
      bloc.add(WorkoutDayPickerStartPressed(h.dayId));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(intents, isEmpty);
      await sub.cancel();
    });
  });
}
