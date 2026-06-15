import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_progress/bloc/exercise_progress/bloc.dart';
import 'package:zamaj/modules/exercise_progress/models/exercise_progress_args.dart';

import '../../support/fake_session_repository.dart';

/// A canonical UUIDv4-shaped id (36 chars) for [Exercise.libraryExerciseId].
const benchLibraryId = '11111111-1111-4111-8111-111111111111';

/// A fake whose first [listCompletedSessions] call throws, then succeeds — used
/// to prove the error state recovers on reload.
class _FailOnceRepo extends FakeSessionRepository {
  _FailOnceRepo({required super.clock});

  bool _failed = false;

  @override
  Future<List<Session>> listCompletedSessions() async {
    if (!_failed) {
      _failed = true;
      throw const NotFoundError(entityType: 'Session', id: 'boom');
    }
    return super.listCompletedSessions();
  }
}

void main() {
  group('ExerciseProgressArgs', () {
    test(
      'carries a nullable library id, measurement type, and display name',
      () {
        const linked = ExerciseProgressArgs(
          libraryExerciseId: 'lib-1',
          measurementType: MeasurementType.repBased(),
          displayName: 'Bench Press',
        );
        expect(linked.libraryExerciseId, 'lib-1');
        expect(linked.measurementType, const MeasurementType.repBased());
        expect(linked.displayName, 'Bench Press');

        const unlinked = ExerciseProgressArgs(
          libraryExerciseId: null,
          measurementType: MeasurementType.repBased(),
          displayName: 'Mystery Move',
        );
        expect(unlinked.libraryExerciseId, isNull);
      },
    );
  });

  group('ExerciseProgressState union', () {
    final point = ProgressPoint(
      date: DateTime.utc(2026, 3, 1),
      topSetWeightKg: 80,
      reps: 8,
      programId: 'p',
      sourceWorkoutDayName: 'Push',
    );
    final series = ExerciseProgressSeries(points: [point, point]);

    test('same-shape states with equal payloads are equal', () {
      expect(const ExerciseProgressLoading(), const ExerciseProgressLoading());
      expect(ExerciseProgressTrend(series), ExerciseProgressTrend(series));
      expect(ExerciseProgressSingle(point), ExerciseProgressSingle(point));
      expect(
        const ExerciseProgressEmptyNoSessions(),
        const ExerciseProgressEmptyNoSessions(),
      );
      expect(
        const ExerciseProgressUnsupportedType(),
        const ExerciseProgressUnsupportedType(),
      );
      expect(
        const ExerciseProgressUnlinked(),
        const ExerciseProgressUnlinked(),
      );
      expect(const ExerciseProgressError(), const ExerciseProgressError());
    });

    test('distinct state variants are not equal', () {
      expect(
        const ExerciseProgressLoading(),
        isNot(const ExerciseProgressEmptyNoSessions()),
      );
      expect(
        const ExerciseProgressUnlinked(),
        isNot(const ExerciseProgressUnsupportedType()),
      );
      expect(
        ExerciseProgressTrend(series),
        isNot(ExerciseProgressSingle(point)),
      );
    });
  });

  group('ExerciseProgressBloc', () {
    final fixedClock = Clock.fixed(DateTime.utc(2026, 6, 1, 12));

    WorkoutDay dayWith(MeasurementType measurementType) {
      final t = DateTime.utc(2024);
      return WorkoutDay(
        id: 'wd-1',
        programId: 'prog-1',
        name: 'Push',
        exerciseGroups: [
          ExerciseGroup(
            id: 'g1',
            workoutDayId: 'wd-1',
            position: 0,
            kind: const ExerciseGroupKind.single(),
            exercises: [
              Exercise(
                id: 'ex-bench',
                exerciseGroupId: 'g1',
                position: 0,
                name: 'Bench Press',
                measurementType: measurementType,
                metadata: ExerciseMetadata.empty,
                libraryExerciseId: benchLibraryId,
                sets: const [],
                createdAt: t,
                updatedAt: t,
                schemaVersion: 1,
              ),
            ],
            createdAt: t,
            updatedAt: t,
            schemaVersion: 1,
          ),
        ],
        createdAt: t,
        updatedAt: t,
        schemaVersion: 1,
      );
    }

    ExerciseProgressArgs argsFor({
      String? libraryExerciseId = benchLibraryId,
      MeasurementType measurementType = const MeasurementType.repBased(),
    }) {
      return ExerciseProgressArgs(
        libraryExerciseId: libraryExerciseId,
        measurementType: measurementType,
        displayName: 'Bench Press',
      );
    }

    /// Starts, logs one [weightKg] set on, and ends a session on the seeded
    /// day, leaving an ended session in [repo].
    Future<void> logEndedSession(
      FakeSessionRepository repo, {
      required double weightKg,
    }) async {
      final session = await repo.startSession(workoutDayId: 'wd-1');
      await repo.completeSet(
        sessionExerciseId: session.sessionExercises.single.id,
        actualValues: ActualSetValues.repBased(weightKg: weightKg, reps: 5),
      );
      await repo.endSession(session.id);
    }

    Future<ExerciseProgressState> load(ExerciseProgressBloc bloc) async {
      bloc.add(const ExerciseProgressLoadRequested());
      // Bounded so a future regression that never reaches a terminal state
      // fails loudly instead of hanging the runner.
      return bloc.stream
          .firstWhere((s) => s is! ExerciseProgressLoading)
          .timeout(const Duration(seconds: 5));
    }

    test('two completed sessions yield a two-point trend', () async {
      final repo = FakeSessionRepository(clock: fixedClock)
        ..seedWorkoutDay(dayWith(const MeasurementType.repBased()));
      await logEndedSession(repo, weightKg: 90);
      await logEndedSession(repo, weightKg: 100);

      final bloc = ExerciseProgressBloc(
        args: argsFor(),
        sessionRepository: repo,
      );
      addTearDown(bloc.close);

      final state = await load(bloc);
      expect(state, isA<ExerciseProgressTrend>());
      expect((state as ExerciseProgressTrend).series.points, hasLength(2));
    });

    test('exactly one completed session yields the single state', () async {
      final repo = FakeSessionRepository(clock: fixedClock)
        ..seedWorkoutDay(dayWith(const MeasurementType.repBased()));
      await logEndedSession(repo, weightKg: 80);

      final bloc = ExerciseProgressBloc(
        args: argsFor(),
        sessionRepository: repo,
      );
      addTearDown(bloc.close);

      final state = await load(bloc);
      expect(state, isA<ExerciseProgressSingle>());
      expect((state as ExerciseProgressSingle).point.topSetWeightKg, 80);
    });

    test('no completed sessions yields the empty state', () async {
      final repo = FakeSessionRepository(clock: fixedClock)
        ..seedWorkoutDay(dayWith(const MeasurementType.repBased()));

      final bloc = ExerciseProgressBloc(
        args: argsFor(),
        sessionRepository: repo,
      );
      addTearDown(bloc.close);

      expect(await load(bloc), isA<ExerciseProgressEmptyNoSessions>());
    });

    test(
      'a time-based exercise yields unsupportedType without reading',
      () async {
        final repo = FakeSessionRepository(clock: fixedClock);
        final bloc = ExerciseProgressBloc(
          args: argsFor(measurementType: const MeasurementType.timeBased()),
          sessionRepository: repo,
        );
        addTearDown(bloc.close);

        expect(await load(bloc), isA<ExerciseProgressUnsupportedType>());
      },
    );

    test(
      'a bodyweight exercise yields unsupportedType without reading',
      () async {
        final repo = FakeSessionRepository(clock: fixedClock);
        final bloc = ExerciseProgressBloc(
          args: argsFor(measurementType: const MeasurementType.bodyweight()),
          sessionRepository: repo,
        );
        addTearDown(bloc.close);

        expect(await load(bloc), isA<ExerciseProgressUnsupportedType>());
      },
    );

    test('a null library id yields the unlinked state', () async {
      final repo = FakeSessionRepository(clock: fixedClock);
      final bloc = ExerciseProgressBloc(
        args: argsFor(libraryExerciseId: null),
        sessionRepository: repo,
      );
      addTearDown(bloc.close);

      expect(await load(bloc), isA<ExerciseProgressUnlinked>());
    });

    test(
      'a read failure surfaces the error state and recovers on reload',
      () async {
        final repo = _FailOnceRepo(clock: fixedClock)
          ..seedWorkoutDay(dayWith(const MeasurementType.repBased()));
        await logEndedSession(repo, weightKg: 80);

        final bloc = ExerciseProgressBloc(
          args: argsFor(),
          sessionRepository: repo,
        );
        addTearDown(bloc.close);

        expect(await load(bloc), isA<ExerciseProgressError>());
        // Re-dispatching load recovers to the data state.
        expect(await load(bloc), isA<ExerciseProgressSingle>());
      },
    );

    test('a deleted session disappears on the next load', () async {
      final repo = FakeSessionRepository(clock: fixedClock)
        ..seedWorkoutDay(dayWith(const MeasurementType.repBased()));
      final first = await repo.startSession(workoutDayId: 'wd-1');
      await repo.completeSet(
        sessionExerciseId: first.sessionExercises.single.id,
        actualValues: const ActualSetValues.repBased(weightKg: 90, reps: 5),
      );
      await repo.endSession(first.id);
      await logEndedSession(repo, weightKg: 100);

      final bloc = ExerciseProgressBloc(
        args: argsFor(),
        sessionRepository: repo,
      );
      addTearDown(bloc.close);

      expect(await load(bloc), isA<ExerciseProgressTrend>());

      await repo.deleteSession(first.id);

      final reloaded = await load(bloc);
      expect(reloaded, isA<ExerciseProgressSingle>());
      expect((reloaded as ExerciseProgressSingle).point.topSetWeightKg, 100);
    });
  });
}
