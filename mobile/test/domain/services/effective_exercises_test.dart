import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/effective_exercises.dart';

final _t = DateTime.utc(2026, 1, 1);

PlannedSetValues _plannedFor(MeasurementType mt, int i) => switch (mt) {
  RepBasedMeasurement() => PlannedSetValues.repBased(
    weightKg: 100.0 + i,
    repTarget: RepTarget.fixed(reps: 5 + i),
  ),
  TimeBasedMeasurement() => PlannedSetValues.timeBased(durationSeconds: 30 + i),
  BodyweightMeasurement() => PlannedSetValues.bodyweight(
    repTarget: RepTarget.fixed(reps: 10 + i),
  ),
};

Exercise _exercise({
  required String id,
  required String groupId,
  MeasurementType measurementType = const MeasurementType.repBased(),
  String name = 'Bench Press',
  int setCount = 3,
}) {
  return Exercise(
    id: id,
    exerciseGroupId: groupId,
    position: 0,
    name: name,
    measurementType: measurementType,
    metadata: ExerciseMetadata.empty,
    sets: List.generate(
      setCount,
      (i) => WorkoutSet(
        id: 'set-$id-$i',
        exerciseId: id,
        position: i,
        measurementType: measurementType,
        plannedValues: _plannedFor(measurementType, i),
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ),
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

ExerciseGroup _group({
  required String id,
  required List<Exercise> exercises,
  ExerciseGroupRole role = ExerciseGroupRole.main,
}) {
  return ExerciseGroup(
    id: id,
    workoutDayId: 'wd',
    position: 0,
    kind: exercises.length == 1
        ? const ExerciseGroupKind.single()
        : const ExerciseGroupKind.superset(),
    exercises: exercises,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
    role: role,
  );
}

SessionExercise _sessionExercise({
  required String plannedId,
  ExerciseState state = const ExerciseState.unfinished(),
  int position = 0,
}) {
  return SessionExercise(
    id: 'se-$plannedId',
    sessionId: 's',
    position: position,
    plannedExerciseIdInSnapshot: plannedId,
    state: state,
    executedSets: const [],
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

Session _session({
  required List<ExerciseGroup> groups,
  required List<SessionExercise> sessionExercises,
}) {
  final workoutDay = WorkoutDay(
    id: 'wd',
    programId: 'p',
    name: 'Day',
    exerciseGroups: groups,
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
    id: 's',
    workoutDayId: 'wd',
    snapshot: snapshot,
    sessionExercises: sessionExercises,
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

void main() {
  group('EffectiveExercises.of', () {
    test('resolves a planned exercise from the snapshot', () {
      final planned = _exercise(id: 'ex1', groupId: 'g1', setCount: 3);
      final se = _sessionExercise(plannedId: 'ex1');
      final session = _session(
        groups: [
          _group(
            id: 'g1',
            exercises: [planned],
            role: ExerciseGroupRole.warmup,
          ),
        ],
        sessionExercises: [se],
      );

      final eff = EffectiveExercises.of(session).forSessionExercise(se);

      expect(eff.plannedExercise.id, 'ex1');
      expect(eff.effectiveMeasurementType, const MeasurementType.repBased());
      expect(eff.plannedSetCount, 3);
      expect(eff.displayName, 'Bench Press');
      expect(eff.plannedGroupRole, ExerciseGroupRole.warmup);
    });

    test(
      'throws NotFoundError when the planned exercise is absent (no set-count-0, no main fallback)',
      () {
        final planned = _exercise(id: 'ex1', groupId: 'g1');
        final se = _sessionExercise(plannedId: 'missing');
        final session = _session(
          groups: [
            _group(id: 'g1', exercises: [planned]),
          ],
          sessionExercises: [se],
        );

        expect(
          () => EffectiveExercises.of(session).forSessionExercise(se),
          throwsA(isA<NotFoundError>().having((e) => e.id, 'id', 'missing')),
        );
      },
    );

    test('plannedValuesAt resolves the snapshot set at a position', () {
      final planned = _exercise(id: 'ex1', groupId: 'g1', setCount: 3);
      final se = _sessionExercise(plannedId: 'ex1');
      final session = _session(
        groups: [
          _group(id: 'g1', exercises: [planned]),
        ],
        sessionExercises: [se],
      );

      final eff = EffectiveExercises.of(session).forSessionExercise(se);

      expect(
        eff.plannedValuesAt(0),
        _plannedFor(const MeasurementType.repBased(), 0),
      );
      expect(
        eff.plannedValuesAt(2),
        _plannedFor(const MeasurementType.repBased(), 2),
      );
    });
  });
}
