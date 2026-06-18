import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/deload_transform.dart';

final _t = DateTime.utc(2020);

WorkoutSet _set(String exerciseId, int position) => WorkoutSet(
  id: 'set-$exerciseId-$position',
  exerciseId: exerciseId,
  position: position,
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 20,
    repTarget: RepTarget.fixed(reps: 5),
  ),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

Exercise _exercise(String id, String groupId, int setCount) => Exercise(
  id: id,
  exerciseGroupId: groupId,
  position: 0,
  name: 'Ex $id',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: List.generate(setCount, (i) => _set(id, i)),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

ExerciseGroup _group({
  required String id,
  required int position,
  required ExerciseGroupRole role,
  required List<Exercise> exercises,
}) => ExerciseGroup(
  id: id,
  workoutDayId: 'day-1',
  position: position,
  kind: ExerciseGroupKind.forMemberCount(exercises.length),
  role: role,
  exercises: exercises,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

WorkoutDay _day(List<ExerciseGroup> groups) => WorkoutDay(
  id: 'day-1',
  programId: 'prog-1',
  name: 'Day',
  exerciseGroups: groups,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

Exercise _onlyExercise(WorkoutDay day) =>
    day.exerciseGroups.single.exercises.single;

void main() {
  group('DeloadTransform.halveWorkingSets', () {
    for (final (planned, deload) in const [
      (1, 1),
      (2, 1),
      (3, 2),
      (4, 2),
      (5, 3),
    ]) {
      test('a main exercise planned for $planned sets becomes $deload sets, '
          'first sets preserved in order', () {
        final day = _day([
          _group(
            id: 'main',
            position: 0,
            role: ExerciseGroupRole.main,
            exercises: [_exercise('e1', 'main', planned)],
          ),
        ]);

        final result = DeloadTransform.halveWorkingSets(day);

        final resultSets = _onlyExercise(result).sets;
        expect(resultSets.length, deload);
        expect(
          resultSets.map((s) => s.id).toList(),
          _onlyExercise(day).sets.take(deload).map((s) => s.id).toList(),
        );
      });
    }

    test('warmup groups keep their full set count; main groups are halved', () {
      final day = _day([
        _group(
          id: 'warmup',
          position: 0,
          role: ExerciseGroupRole.warmup,
          exercises: [_exercise('w1', 'warmup', 3)],
        ),
        _group(
          id: 'main',
          position: 1,
          role: ExerciseGroupRole.main,
          exercises: [_exercise('m1', 'main', 4)],
        ),
      ]);

      final result = DeloadTransform.halveWorkingSets(day);

      final warmup = result.exerciseGroups[0];
      final main = result.exerciseGroups[1];
      expect(warmup.exercises.single.sets.length, 3);
      expect(main.exercises.single.sets.length, 2);
    });

    test('the source workout day is not mutated', () {
      final day = _day([
        _group(
          id: 'main',
          position: 0,
          role: ExerciseGroupRole.main,
          exercises: [_exercise('e1', 'main', 4)],
        ),
      ]);

      DeloadTransform.halveWorkingSets(day);

      expect(_onlyExercise(day).sets.length, 4);
    });
  });
}
