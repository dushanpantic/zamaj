// End-to-end test for [DriftSessionRepository.createSuperset]. Verifies the
// real Drift transaction repositions the chosen members into one contiguous
// block so the assembler's contiguous-run detection treats them as a single
// group. Without repositioning, grouping non-adjacent exercises (or members
// split by a locked exercise) leaves orphaned same-tag singles that render as
// standalone cards — undraggable, with no ungroup affordance.

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain_se;
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

Future<({String sessionId, List<String> ids})>
_startSessionWithStandaloneExercises(
  DriftProgramRepository programRepo,
  DriftSessionRepository sessionRepo,
  Random rng, {
  required int count,
}) async {
  final program = await programRepo.createProgram(name: 'P');
  final workoutDay = await programRepo.createWorkoutDay(
    programId: program.id,
    name: 'D',
  );
  for (var i = 0; i < count; i++) {
    await programRepo.createExerciseGroup(
      workoutDayId: workoutDay.id,
      kind: const ExerciseGroupKind.single(),
      exercises: [
        domain.Exercise(
          id: anyUuidV4(rng),
          exerciseGroupId: '',
          position: 0,
          name: 'Exercise $i',
          measurementType: const MeasurementType.repBased(),
          metadata: ExerciseMetadata.empty,
          sets: const [],
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          schemaVersion: 1,
        ),
      ],
    );
  }
  final session = await sessionRepo.startSession(workoutDayId: workoutDay.id);
  final sorted = List<domain_se.SessionExercise>.of(session.sessionExercises)
    ..sort((a, b) => a.position.compareTo(b.position));
  return (sessionId: session.id, ids: sorted.map((e) => e.id).toList());
}

List<int> _memberIndices(
  List<domain_se.SessionExercise> exercises,
  String tag,
) {
  final sorted = List<domain_se.SessionExercise>.of(exercises)
    ..sort((a, b) => a.position.compareTo(b.position));
  return [
    for (var i = 0; i < sorted.length; i++)
      if (sorted[i].supersetTag == tag) i,
  ];
}

void _expectAdjacent(List<int> memberIndices) {
  for (var i = 1; i < memberIndices.length; i++) {
    expect(
      memberIndices[i],
      equals(memberIndices[i - 1] + 1),
      reason:
          'superset members must be adjacent in position order (no non-member '
          'between them) so the assembler renders one contiguous group',
    );
  }
}

void main() {
  group('DriftSessionRepository.createSuperset', () {
    test('grouping two non-adjacent exercises repositions them into a '
        'contiguous block sharing a single tag', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );
        final (:sessionId, :ids) = await _startSessionWithStandaloneExercises(
          programRepo,
          sessionRepo,
          Random(0),
          count: 4,
        );
        expect(ids.length, equals(4));

        // Group ids[0] and ids[2] — ids[1] sits between them.
        final result = await sessionRepo.createSuperset(
          sessionId: sessionId,
          sessionExerciseIds: [ids[0], ids[2]],
        );

        final tags = result.sessionExercises
            .where((e) => e.supersetTag != null)
            .map((e) => e.supersetTag)
            .toSet();
        expect(tags.length, equals(1));
        final tag = tags.single!;
        expect(
          result.sessionExercises
              .where((e) => e.supersetTag == tag)
              .map((e) => e.id)
              .toSet(),
          equals({ids[0], ids[2]}),
        );

        final memberIndices = _memberIndices(result.sessionExercises, tag);
        expect(memberIndices.length, equals(2));
        _expectAdjacent(memberIndices);

        // Order within the block follows the provided id order.
        final sorted = List<domain_se.SessionExercise>.of(
          result.sessionExercises,
        )..sort((a, b) => a.position.compareTo(b.position));
        expect(sorted[memberIndices.first].id, equals(ids[0]));
        expect(sorted[memberIndices.last].id, equals(ids[2]));

        // Two-phase write left positions unique.
        final positions = sorted.map((e) => e.position).toList();
        expect(positions.toSet().length, equals(positions.length));
      } finally {
        await db.close();
      }
    });

    test('grouping across a locked exercise still yields a contiguous block, '
        'pushing the locked exercise out of the run', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );
        final (:sessionId, :ids) = await _startSessionWithStandaloneExercises(
          programRepo,
          sessionRepo,
          Random(1),
          count: 4,
        );

        // Skip ids[1] so a locked exercise sits between ids[0] and ids[2].
        await sessionRepo.skipExercise(ids[1]);

        final result = await sessionRepo.createSuperset(
          sessionId: sessionId,
          sessionExerciseIds: [ids[0], ids[2]],
        );

        final tag = result.sessionExercises
            .firstWhere((e) => e.id == ids[0])
            .supersetTag!;
        expect(
          result.sessionExercises.firstWhere((e) => e.id == ids[2]).supersetTag,
          equals(tag),
        );

        final memberIndices = _memberIndices(result.sessionExercises, tag);
        expect(memberIndices.length, equals(2));
        _expectAdjacent(memberIndices);

        // The locked exercise no longer sits between the two members.
        final sorted = List<domain_se.SessionExercise>.of(
          result.sessionExercises,
        )..sort((a, b) => a.position.compareTo(b.position));
        final skipped = sorted.firstWhere((e) => e.id == ids[1]);
        expect(skipped.state, isA<SkippedState>());
        expect(skipped.supersetTag, isNull);

        final positions = sorted.map((e) => e.position).toList();
        expect(positions.toSet().length, equals(positions.length));
      } finally {
        await db.close();
      }
    });
  });
}
