import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';

import '../support/generators.dart';

void main() {
  group('Property 2: ExerciseGroup cardinality', () {
    test('single kind with exactly one exercise constructs without error', () {
      final rng = Random(100);
      for (var i = 0; i < 100; i++) {
        final group = ExerciseGroup(
          id: anyUuidV4(rng),
          workoutDayId: anyUuidV4(rng),
          position: i,
          kind: const ExerciseGroupKind.single(),
          exercises: [anyExercise(rng)],
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
        expect(group.exercises.length, equals(1));
        expect(group.kind, isA<SingleKind>());
      }
    });

    test('superset kind with 2+ exercises constructs without error', () {
      final rng = Random(101);
      for (var i = 0; i < 100; i++) {
        final count = 2 + rng.nextInt(4);
        final group = ExerciseGroup(
          id: anyUuidV4(rng),
          workoutDayId: anyUuidV4(rng),
          position: i,
          kind: const ExerciseGroupKind.superset(),
          exercises: List.generate(count, (_) => anyExercise(rng)),
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
        expect(group.exercises.length, greaterThanOrEqualTo(2));
        expect(group.kind, isA<SupersetKind>());
      }
    });

    test(
      'single kind with zero exercises throws ValidationError with correct invariant',
      () {
        final rng = Random(102);
        for (var i = 0; i < 100; i++) {
          final id = anyUuidV4(rng);
          final now = anyUtcDateTime(rng);

          final error = _expectValidationError(
            () => ExerciseGroup(
              id: id,
              workoutDayId: anyUuidV4(rng),
              position: 0,
              kind: const ExerciseGroupKind.single(),
              exercises: [],
              createdAt: now,
              updatedAt: now,
              schemaVersion: 1,
            ),
          );
          expect(error.entityId, equals(id));
          expect(
            error.invariant,
            equals('single_requires_exactly_one_exercise'),
          );
        }
      },
    );

    test(
      'single kind with 2+ exercises throws ValidationError with correct invariant',
      () {
        final rng = Random(103);
        for (var i = 0; i < 100; i++) {
          final id = anyUuidV4(rng);
          final now = anyUtcDateTime(rng);
          final count = 2 + rng.nextInt(4);

          final error = _expectValidationError(
            () => ExerciseGroup(
              id: id,
              workoutDayId: anyUuidV4(rng),
              position: 0,
              kind: const ExerciseGroupKind.single(),
              exercises: List.generate(count, (_) => anyExercise(rng)),
              createdAt: now,
              updatedAt: now,
              schemaVersion: 1,
            ),
          );
          expect(error.entityId, equals(id));
          expect(
            error.invariant,
            equals('single_requires_exactly_one_exercise'),
          );
        }
      },
    );

    test(
      'superset kind with zero exercises throws ValidationError with correct invariant',
      () {
        final rng = Random(104);
        for (var i = 0; i < 100; i++) {
          final id = anyUuidV4(rng);
          final now = anyUtcDateTime(rng);

          final error = _expectValidationError(
            () => ExerciseGroup(
              id: id,
              workoutDayId: anyUuidV4(rng),
              position: 0,
              kind: const ExerciseGroupKind.superset(),
              exercises: [],
              createdAt: now,
              updatedAt: now,
              schemaVersion: 1,
            ),
          );
          expect(error.entityId, equals(id));
          expect(
            error.invariant,
            equals('superset_requires_at_least_two_exercises'),
          );
        }
      },
    );

    test(
      'superset kind with exactly one exercise throws ValidationError with correct invariant',
      () {
        final rng = Random(105);
        for (var i = 0; i < 100; i++) {
          final id = anyUuidV4(rng);
          final now = anyUtcDateTime(rng);

          final error = _expectValidationError(
            () => ExerciseGroup(
              id: id,
              workoutDayId: anyUuidV4(rng),
              position: 0,
              kind: const ExerciseGroupKind.superset(),
              exercises: [anyExercise(rng)],
              createdAt: now,
              updatedAt: now,
              schemaVersion: 1,
            ),
          );
          expect(error.entityId, equals(id));
          expect(
            error.invariant,
            equals('superset_requires_at_least_two_exercises'),
          );
        }
      },
    );

    test('anyExerciseGroup generator always produces valid groups', () {
      final rng = Random(106);
      for (var i = 0; i < 100; i++) {
        final group = anyExerciseGroup(rng);
        group.kind.when(
          single: () => expect(group.exercises.length, equals(1)),
          superset: () =>
              expect(group.exercises.length, greaterThanOrEqualTo(2)),
        );
      }
    });
  });
}

ValidationError _expectValidationError(void Function() fn) {
  try {
    fn();
    fail('Expected ValidationError but no exception was thrown');
  } on ValidationError catch (e) {
    return e;
  }
}
