import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/services/session_seed.dart';

final _t = DateTime.utc(2026, 1, 1);

Exercise _exercise(String id, String groupId) => Exercise(
  id: id,
  exerciseGroupId: groupId,
  position: 0,
  name: 'Ex $id',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: const [],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

ExerciseGroup _group({
  required String id,
  required ExerciseGroupKind kind,
  required List<Exercise> exercises,
}) => ExerciseGroup(
  id: id,
  workoutDayId: 'wd',
  position: 0,
  kind: kind,
  exercises: exercises,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
  role: ExerciseGroupRole.main,
);

WorkoutDay _workoutDay(List<ExerciseGroup> groups) => WorkoutDay(
  id: 'wd',
  programId: 'p',
  name: 'Day',
  exerciseGroups: groups,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

void main() {
  group('SessionSeed.fromWorkoutDay', () {
    test('flattens groups in group-then-member order', () {
      final day = _workoutDay([
        _group(
          id: 'g1',
          kind: const ExerciseGroupKind.single(),
          exercises: [_exercise('e1', 'g1')],
        ),
        _group(
          id: 'g2',
          kind: const ExerciseGroupKind.superset(),
          exercises: [_exercise('e2', 'g2'), _exercise('e3', 'g2')],
        ),
      ]);

      final seed = SessionSeed.fromWorkoutDay(day);

      expect(seed.map((e) => e.plannedExerciseIdInSnapshot).toList(), [
        'e1',
        'e2',
        'e3',
      ]);
    });

    test('a single-group exercise carries no superset tag', () {
      final day = _workoutDay([
        _group(
          id: 'g1',
          kind: const ExerciseGroupKind.single(),
          exercises: [_exercise('e1', 'g1')],
        ),
      ]);

      final seed = SessionSeed.fromWorkoutDay(day);

      expect(seed.single.supersetTag, isNull);
    });

    test('superset members carry the group id as their superset tag', () {
      final day = _workoutDay([
        _group(
          id: 'g2',
          kind: const ExerciseGroupKind.superset(),
          exercises: [_exercise('e2', 'g2'), _exercise('e3', 'g2')],
        ),
      ]);

      final seed = SessionSeed.fromWorkoutDay(day);

      expect(seed.every((e) => e.supersetTag == 'g2'), isTrue);
    });
  });
}
