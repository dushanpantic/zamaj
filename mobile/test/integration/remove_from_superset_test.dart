// End-to-end test for [DriftSessionRepository.removeFromSuperset]. Verifies the
// real Drift transaction: extracting a member clears its tag, lands it
// immediately after the group's last remaining member, keeps the remaining
// members one contiguous run, dodges the (session_id, position) UNIQUE
// constraint, and re-asserts the engine preconditions (no-tag, finished-member,
// ended-session). The atomicity test forces a fault after the position rewrite
// but before the tag clear and asserts the whole extraction rolls back — the
// core justification for the new single-transaction primitive.

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain_se;
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

/// A repo whose [debugRemoveFromSupersetBarrier] faults mid-transaction — after
/// the two-phase position rewrite has executed but before the extracted member's
/// tag is cleared — so the rollback behavior (true atomicity) can be asserted.
class _FaultyExtractRepo extends DriftSessionRepository {
  _FaultyExtractRepo({required super.db, required super.programRepository});

  @override
  Future<void> debugRemoveFromSupersetBarrier() async {
    throw StateError('simulated mid-extraction fault');
  }
}

Future<
  ({AppDatabase db, DriftProgramRepository programRepo, String workoutDayId})
>
_seed() async {
  final db = AppDatabase(NativeDatabase.memory());
  final programRepo = DriftProgramRepository(db: db);
  final rng = Random(0);
  final program = await programRepo.createProgram(name: 'P');
  final workoutDay = await programRepo.createWorkoutDay(
    programId: program.id,
    name: 'D',
  );
  for (var i = 0; i < 5; i++) {
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
  return (db: db, programRepo: programRepo, workoutDayId: workoutDay.id);
}

List<domain_se.SessionExercise> _sorted(domain.Session session) =>
    List<domain_se.SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

void main() {
  group('DriftSessionRepository.removeFromSuperset', () {
    test(
      'extracts the middle member: remaining members stay one contiguous '
      'superset, the extracted lands directly below, positions stay unique',
      () async {
        final seed = await _seed();
        final repo = DriftSessionRepository(
          db: seed.db,
          programRepository: seed.programRepo,
        );
        try {
          final session = await repo.startSession(
            workoutDayId: seed.workoutDayId,
          );
          final ids = _sorted(session).map((e) => e.id).toList();
          final afterCreate = await repo.createSuperset(
            sessionId: session.id,
            sessionExerciseIds: [ids[1], ids[2], ids[3]],
          );
          final tag = afterCreate.sessionExercises
              .firstWhere((e) => e.id == ids[1])
              .supersetTag!;

          final result = await repo.removeFromSuperset(
            sessionId: session.id,
            sessionExerciseId: ids[2],
          );

          // Extracted member: tag cleared, still unfinished.
          final extracted = result.sessionExercises.firstWhere(
            (e) => e.id == ids[2],
          );
          expect(extracted.supersetTag, isNull);
          expect(extracted.state, isA<UnfinishedState>());

          // Order: standalone, [member, member], extracted, standalone.
          final order = _sorted(result).map((e) => e.id).toList();
          expect(order, [ids[0], ids[1], ids[3], ids[2], ids[4]]);

          // Remaining members are adjacent in position order — one contiguous run.
          final sorted = _sorted(result);
          final memberIndices = <int>[
            for (var i = 0; i < sorted.length; i++)
              if (sorted[i].supersetTag == tag) i,
          ];
          expect(memberIndices, [1, 2]);

          // Positions remain unique — the two-phase write avoided a collision.
          final positions = result.sessionExercises
              .map((e) => e.position)
              .toList();
          expect(positions.toSet().length, positions.length);

          // Reloads identically from disk (single committed round-trip).
          final reloaded = (await repo.getSession(session.id))!;
          expect(_sorted(reloaded).map((e) => e.id).toList(), order);
        } finally {
          await seed.db.close();
        }
      },
    );

    test('refuses an ungrouped exercise and leaves rows unchanged', () async {
      final seed = await _seed();
      final repo = DriftSessionRepository(
        db: seed.db,
        programRepository: seed.programRepo,
      );
      try {
        final session = await repo.startSession(
          workoutDayId: seed.workoutDayId,
        );
        final ids = _sorted(session).map((e) => e.id).toList();
        await repo.createSuperset(
          sessionId: session.id,
          sessionExerciseIds: [ids[1], ids[2], ids[3]],
        );
        final before = _sorted((await repo.getSession(session.id))!);

        await expectLater(
          repo.removeFromSuperset(
            sessionId: session.id,
            sessionExerciseId: ids[0],
          ),
          throwsA(isA<ValidationError>()),
        );

        final after = _sorted((await repo.getSession(session.id))!);
        expect(
          after.map((e) => (e.id, e.position, e.supersetTag)),
          before.map((e) => (e.id, e.position, e.supersetTag)),
        );
      } finally {
        await seed.db.close();
      }
    });

    test(
      'refuses when a group member is finished and leaves rows unchanged',
      () async {
        final seed = await _seed();
        final repo = DriftSessionRepository(
          db: seed.db,
          programRepository: seed.programRepo,
        );
        try {
          final session = await repo.startSession(
            workoutDayId: seed.workoutDayId,
          );
          final ids = _sorted(session).map((e) => e.id).toList();
          await repo.createSuperset(
            sessionId: session.id,
            sessionExerciseIds: [ids[1], ids[2], ids[3]],
          );
          await repo.skipExercise(ids[1]);
          final before = _sorted((await repo.getSession(session.id))!);

          await expectLater(
            repo.removeFromSuperset(
              sessionId: session.id,
              sessionExerciseId: ids[2],
            ),
            throwsA(isA<OrderingError>()),
          );

          final after = _sorted((await repo.getSession(session.id))!);
          expect(
            after.map((e) => (e.id, e.position, e.supersetTag)),
            before.map((e) => (e.id, e.position, e.supersetTag)),
          );
        } finally {
          await seed.db.close();
        }
      },
    );

    test(
      'refuses once the session has ended and leaves rows unchanged',
      () async {
        final seed = await _seed();
        final repo = DriftSessionRepository(
          db: seed.db,
          programRepository: seed.programRepo,
        );
        try {
          final session = await repo.startSession(
            workoutDayId: seed.workoutDayId,
          );
          final ids = _sorted(session).map((e) => e.id).toList();
          await repo.createSuperset(
            sessionId: session.id,
            sessionExerciseIds: [ids[1], ids[2], ids[3]],
          );
          await repo.endSession(session.id);
          final before = _sorted((await repo.getSession(session.id))!);

          await expectLater(
            repo.removeFromSuperset(
              sessionId: session.id,
              sessionExerciseId: ids[2],
            ),
            throwsA(isA<ImmutabilityError>()),
          );

          final after = _sorted((await repo.getSession(session.id))!);
          expect(
            after.map((e) => (e.id, e.position, e.supersetTag)),
            before.map((e) => (e.id, e.position, e.supersetTag)),
          );
        } finally {
          await seed.db.close();
        }
      },
    );

    test(
      'rolls back fully when a fault is injected after the position rewrite '
      'but before the tag clear: positions and tags are exactly as before',
      () async {
        final seed = await _seed();
        final faulty = _FaultyExtractRepo(
          db: seed.db,
          programRepository: seed.programRepo,
        );
        try {
          final session = await faulty.startSession(
            workoutDayId: seed.workoutDayId,
          );
          final ids = _sorted(session).map((e) => e.id).toList();
          await faulty.createSuperset(
            sessionId: session.id,
            sessionExerciseIds: [ids[1], ids[2], ids[3]],
          );
          final before = _sorted((await faulty.getSession(session.id))!);

          await expectLater(
            faulty.removeFromSuperset(
              sessionId: session.id,
              sessionExerciseId: ids[2],
            ),
            throwsA(isA<StateError>()),
          );

          // The whole transaction rolled back: every position and tag is intact,
          // so the three members still form one contiguous superset — no split run.
          final after = _sorted((await faulty.getSession(session.id))!);
          expect(
            after.map((e) => (e.id, e.position, e.supersetTag)),
            before.map((e) => (e.id, e.position, e.supersetTag)),
          );
        } finally {
          await seed.db.close();
        }
      },
    );
  });
}
