// Pins that startSession materialises the domain SessionSeed: session exercises
// appear in group-then-member order, superset members carry the group tag,
// single-group exercises carry none, and positions stay distinct and ascending
// (the gap constant remains a repo detail).

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

domain.Exercise _exercise(String name) => domain.Exercise(
  id: '',
  exerciseGroupId: '',
  position: 0,
  name: name,
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: const [],
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  schemaVersion: 1,
);

void main() {
  group('DriftSessionRepository.startSession seeding', () {
    test(
      'flattens a single group then a superset group, tagging members',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
          );

          final program = await programRepo.createProgram(name: 'P');
          final workoutDay = await programRepo.createWorkoutDay(
            programId: program.id,
            name: 'D',
          );
          await programRepo.createExerciseGroup(
            workoutDayId: workoutDay.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [_exercise('Squat')],
          );
          await programRepo.createExerciseGroup(
            workoutDayId: workoutDay.id,
            kind: const ExerciseGroupKind.superset(),
            exercises: [_exercise('Curl'), _exercise('Press')],
          );

          // Derive expectations from the persisted day so we compare against the
          // repo-assigned planned ids, in the day's own group/member order.
          final day = (await programRepo.getWorkoutDay(workoutDay.id))!;
          final expectedPlannedIds = [
            for (final g in day.exerciseGroups)
              for (final e in g.exercises) e.id,
          ];
          final supersetGroup = day.exerciseGroups.firstWhere(
            (g) => g.kind is SupersetKind,
          );
          final supersetMemberIds = supersetGroup.exercises
              .map((e) => e.id)
              .toSet();

          final session = await sessionRepo.startSession(
            workoutDayId: workoutDay.id,
          );

          final sorted = List<domain_se.SessionExercise>.of(
            session.sessionExercises,
          )..sort((a, b) => a.position.compareTo(b.position));

          expect(
            sorted.map((e) => e.plannedExerciseIdInSnapshot).toList(),
            expectedPlannedIds,
          );

          for (final se in sorted) {
            if (supersetMemberIds.contains(se.plannedExerciseIdInSnapshot)) {
              expect(se.supersetTag, equals(supersetGroup.id));
            } else {
              expect(se.supersetTag, isNull);
            }
          }

          // Positions distinct and strictly ascending, starting at 0.
          final positions = sorted.map((e) => e.position).toList();
          expect(positions.first, 0);
          expect(positions.toSet().length, positions.length);
          for (var i = 1; i < positions.length; i++) {
            expect(positions[i] > positions[i - 1], isTrue);
          }
        } finally {
          await db.close();
        }
      },
    );
  });
}
