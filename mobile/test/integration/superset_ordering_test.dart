// Pins the exact final session-exercise order produced by createSuperset and
// addToSuperset through the real Drift transaction, guarding the extraction of
// the ordering math into the domain SupersetOrdering service. Complements
// create_superset_test/add_to_superset_test (which assert contiguity) by
// asserting the precise id sequence.

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain_se;
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

Future<({String sessionId, List<String> ids})> _startWithStandalones(
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

List<String> _orderedIds(List<domain_se.SessionExercise> exercises) {
  final sorted = List<domain_se.SessionExercise>.of(exercises)
    ..sort((a, b) => a.position.compareTo(b.position));
  return sorted.map((e) => e.id).toList();
}

void main() {
  group('superset ordering through the repo', () {
    test('createSuperset across a gap anchors at the drop target → '
        '[b, a, c, d]', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );
        final (:sessionId, :ids) = await _startWithStandalones(
          programRepo,
          sessionRepo,
          Random(0),
          count: 4,
        );

        // Drag a (ids[0]) onto target c (ids[2]); the target is passed last and
        // is the anchor, so the new [a, c] block lands at c's slot, not at a's.
        final result = await sessionRepo.createSuperset(
          sessionId: sessionId,
          sessionExerciseIds: [ids[0], ids[2]],
        );

        expect(_orderedIds(result.sessionExercises), [
          ids[1],
          ids[0],
          ids[2],
          ids[3],
        ]);
      } finally {
        await db.close();
      }
    });

    test(
      'addToSuperset drops the dragged id just after the last member',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
          );
          final (:sessionId, :ids) = await _startWithStandalones(
            programRepo,
            sessionRepo,
            Random(1),
            count: 4,
          );

          final created = await sessionRepo.createSuperset(
            sessionId: sessionId,
            sessionExerciseIds: [ids[0], ids[1]],
          );
          final tag = created.sessionExercises
              .firstWhere((e) => e.id == ids[0])
              .supersetTag!;

          final result = await sessionRepo.addToSuperset(
            sessionId: sessionId,
            supersetTag: tag,
            sessionExerciseId: ids[3],
          );

          expect(_orderedIds(result.sessionExercises), [
            ids[0],
            ids[1],
            ids[3],
            ids[2],
          ]);
        } finally {
          await db.close();
        }
      },
    );
  });
}
