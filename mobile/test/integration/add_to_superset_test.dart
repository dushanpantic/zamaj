// End-to-end test for [DriftSessionRepository.addToSuperset]. Verifies the
// real Drift transaction: dragged exercise carries the existing tag, lands
// immediately after the last current member, no UNIQUE constraint violation
// on (session_id, position), and unrelated unfinished exercises stay where
// they were unless they had to shift.

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

void main() {
  group('DriftSessionRepository.addToSuperset', () {
    test(
      'appends an unfinished, ungrouped exercise to an existing '
      'superset and persists contiguous member positions, tag preserved',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
          );

          final rng = Random(0);
          final program = await programRepo.createProgram(name: 'P');
          final workoutDay = await programRepo.createWorkoutDay(
            programId: program.id,
            name: 'D',
          );
          for (var i = 0; i < 4; i++) {
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

          final session = await sessionRepo.startSession(
            workoutDayId: workoutDay.id,
          );
          final sorted = List<domain_se.SessionExercise>.of(
            session.sessionExercises,
          )..sort((a, b) => a.position.compareTo(b.position));
          final ids = sorted.map((e) => e.id).toList();
          expect(ids.length, equals(4));

          // Group ids[0] + ids[1] into a superset.
          final afterCreate = await sessionRepo.createSuperset(
            sessionId: session.id,
            sessionExerciseIds: [ids[0], ids[1]],
          );
          final tag = afterCreate.sessionExercises
              .firstWhere((e) => e.id == ids[0])
              .supersetTag!;

          // Append ids[3] to the existing group.
          final result = await sessionRepo.addToSuperset(
            sessionId: session.id,
            supersetTag: tag,
            sessionExerciseId: ids[3],
          );

          // Tag is preserved (not rotated).
          final groupTags = result.sessionExercises
              .where((e) => e.supersetTag != null)
              .map((e) => e.supersetTag)
              .toSet();
          expect(groupTags, equals({tag}));

          // Dragged is now tagged and unfinished.
          final dragged = result.sessionExercises.firstWhere(
            (e) => e.id == ids[3],
          );
          expect(dragged.supersetTag, equals(tag));
          expect(dragged.state, isA<UnfinishedState>());

          // Group members sit adjacent to each other in position order, with
          // the dragged landing last in the group. "Adjacent" here means no
          // non-member sits between them when the whole session is sorted by
          // position — the assembler's contiguous-run detection works on that
          // ordering, not on raw position deltas.
          final resultSorted = List<domain_se.SessionExercise>.of(
            result.sessionExercises,
          )..sort((a, b) => a.position.compareTo(b.position));
          final memberIndices = <int>[
            for (var i = 0; i < resultSorted.length; i++)
              if (resultSorted[i].supersetTag == tag) i,
          ];
          expect(memberIndices.length, equals(3));
          for (var i = 1; i < memberIndices.length; i++) {
            expect(
              memberIndices[i],
              equals(memberIndices[i - 1] + 1),
              reason:
                  'members must be adjacent in position order (no non-member '
                  'between them)',
            );
          }
          expect(resultSorted[memberIndices.last].id, equals(ids[3]));

          // All positions across the session remain unique — i.e. the
          // two-phase write avoided a UNIQUE-constraint collision.
          final allPositions = resultSorted.map((e) => e.position).toList()
            ..sort();
          expect(allPositions.toSet().length, equals(allPositions.length));
        } finally {
          await db.close();
        }
      },
    );
  });
}
