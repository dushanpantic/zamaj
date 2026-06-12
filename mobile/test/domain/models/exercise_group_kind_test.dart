import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

final _t = DateTime.utc(2026, 1, 1);

Exercise _exercise(String id) => Exercise(
  id: id,
  exerciseGroupId: 'g',
  position: 0,
  name: 'Ex $id',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: const [],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

ExerciseGroup _group(ExerciseGroupKind kind, List<Exercise> exercises) =>
    ExerciseGroup(
      id: 'g',
      workoutDayId: 'wd',
      position: 0,
      kind: kind,
      exercises: exercises,
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    );

ExerciseGroupDraft _draft(int memberCount) => ExerciseGroupDraft(
  draftId: 'd',
  persistedId: null,
  exercises: List.generate(
    memberCount,
    (i) => ExerciseDraft(
      draftId: 'ed$i',
      persistedId: null,
      name: 'Ex $i',
      measurementType: const MeasurementType.repBased(),
      metadata: ExerciseMetadata.empty,
      plannedRestSeconds: null,
      sets: const [],
    ),
  ),
);

void main() {
  group('ExerciseGroupKind.forMemberCount', () {
    test('one member is a single group', () {
      expect(
        ExerciseGroupKind.forMemberCount(1),
        const ExerciseGroupKind.single(),
      );
    });

    test('two or more members are a superset', () {
      expect(
        ExerciseGroupKind.forMemberCount(2),
        const ExerciseGroupKind.superset(),
      );
      expect(
        ExerciseGroupKind.forMemberCount(5),
        const ExerciseGroupKind.superset(),
      );
    });
  });

  group('ExerciseGroupDraft.kind agrees with forMemberCount', () {
    test('a one-member draft is a single group', () {
      expect(_draft(1).kind(), ExerciseGroupKind.forMemberCount(1));
      expect(_draft(1).kind(), const ExerciseGroupKind.single());
    });

    test('a multi-member draft is a superset', () {
      expect(_draft(3).kind(), ExerciseGroupKind.forMemberCount(3));
      expect(_draft(3).kind(), const ExerciseGroupKind.superset());
    });
  });

  group('ExerciseGroup validation agrees with forMemberCount', () {
    test('a single group of one validates and matches the rule', () {
      final g = _group(const ExerciseGroupKind.single(), [_exercise('a')]);
      expect(g.kind, ExerciseGroupKind.forMemberCount(g.exercises.length));
    });

    test('a superset of two validates and matches the rule', () {
      final g = _group(const ExerciseGroupKind.superset(), [
        _exercise('a'),
        _exercise('b'),
      ]);
      expect(g.kind, ExerciseGroupKind.forMemberCount(g.exercises.length));
    });
  });
}
