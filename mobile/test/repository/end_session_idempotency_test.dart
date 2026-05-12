import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/in_memory_app_database.dart';

void main() {
  test(
    'endSession on an already-ended session throws ImmutabilityError',
    () async {
      final helper = InMemoryDatabaseHelper();
      await helper.setUp();
      try {
        final programRepo = DriftProgramRepository(db: helper.db);
        final sessionRepo = DriftSessionRepository(
          db: helper.db,
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
          exercises: [
            domain.Exercise(
              id: '11111111-1111-1111-1111-111111111111',
              exerciseGroupId: '',
              position: 0,
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: const [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );

        final session = await sessionRepo.startSession(workoutDayId: day.id);
        final ended = await sessionRepo.endSession(session.id);
        expect(ended.endedAt, isNotNull);

        await expectLater(
          () => sessionRepo.endSession(session.id),
          throwsA(
            isA<ImmutabilityError>().having(
              (e) => e.sessionId,
              'sessionId',
              equals(session.id),
            ),
          ),
        );
      } finally {
        await helper.tearDown();
      }
    },
  );
}
