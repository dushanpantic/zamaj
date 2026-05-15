import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

import '../support/generators.dart';

void main() {
  const iterations = 100;

  group('Property 3: Replacement invariant', () {
    group('sealed-encoding construction level', () {
      test(
        'replaced state carries non-null substitute accessible via state',
        () {
          final rng = Random(300);
          for (var i = 0; i < iterations; i++) {
            final substitute = anySubstituteExercise(rng);
            final state = ExerciseState.replaced(substitute: substitute);

            expect(state, isA<ReplacedState>());
            final replaced = state as ReplacedState;
            expect(replaced.substitute, equals(substitute));
            expect(replaced.substitute.name, isNotEmpty);
          }
        },
      );

      test(
        'non-replaced states carry no substitute payload at the type level',
        () {
          final rng = Random(301);
          for (var i = 0; i < iterations; i++) {
            final nonReplacedStates = [
              const ExerciseState.unfinished(),
              const ExerciseState.completed(),
              const ExerciseState.skipped(),
            ];
            final state =
                nonReplacedStates[rng.nextInt(nonReplacedStates.length)];

            expect(state, isNot(isA<ReplacedState>()));
          }
        },
      );

      test(
        'SessionExercise with replaced state exposes substitute through state',
        () {
          final rng = Random(302);
          for (var i = 0; i < iterations; i++) {
            final substitute = anySubstituteExercise(rng);
            final state = ExerciseState.replaced(substitute: substitute);
            final now = anyUtcDateTime(rng);
            final se = SessionExercise(
              id: anyUuidV4(rng),
              sessionId: anyUuidV4(rng),
              position: rng.nextInt(10),
              plannedExerciseIdInSnapshot: anyUuidV4(rng),
              state: state,
              executedSets: const [],
              createdAt: now,
              updatedAt: now,
              schemaVersion: 1,
            );

            expect(se.state, isA<ReplacedState>());
            final replaced = se.state as ReplacedState;
            expect(replaced.substitute, equals(substitute));
          }
        },
      );

      test(
        'plannedExerciseIdInSnapshot is always non-null on SessionExercise',
        () {
          final rng = Random(303);
          for (var i = 0; i < iterations; i++) {
            final se = anySessionExercise(rng);
            expect(se.plannedExerciseIdInSnapshot, isNotNull);
            expect(se.plannedExerciseIdInSnapshot.length, equals(36));
          }
        },
      );
    });

    group('JSON boundary', () {
      test('replaced ExerciseState round-trips with substitute intact', () {
        final rng = Random(304);
        for (var i = 0; i < iterations; i++) {
          final substitute = anySubstituteExercise(rng);
          final original = ExerciseState.replaced(substitute: substitute);

          final roundTripped = ExerciseState.fromJson(original.toJson());

          expect(roundTripped, isA<ReplacedState>());
          final replaced = roundTripped as ReplacedState;
          expect(replaced.substitute, equals(substitute));
          expect(replaced.substitute.name, equals(substitute.name));
          expect(
            replaced.substitute.measurementType,
            equals(substitute.measurementType),
          );
        }
      });

      test(
        'non-replaced state JSON with injected substitute field raises DeserializationError',
        () {
          final rng = Random(305);
          final nonReplacedTypes = ['unfinished', 'completed', 'skipped'];
          for (var i = 0; i < iterations; i++) {
            final stateType =
                nonReplacedTypes[rng.nextInt(nonReplacedTypes.length)];
            final substitute = anySubstituteExercise(rng);
            final corrupted = <String, dynamic>{
              'type': stateType,
              'substitute': substitute.toJson(),
            };

            final result = ExerciseState.fromJson(corrupted);
            expect(
              result,
              isNot(isA<ReplacedState>()),
              reason:
                  'Non-replaced state should ignore injected substitute field',
            );
          }
        },
      );

      test(
        'replaced state JSON with missing substitute raises DeserializationError',
        () {
          for (var i = 0; i < iterations; i++) {
            final corrupted = <String, dynamic>{'type': 'replaced'};

            try {
              ExerciseState.fromJson(corrupted);
              fail('Expected DeserializationError but no exception was thrown');
            } on DeserializationError catch (e) {
              expect(e.field, equals('substitute'));
            }
          }
        },
      );

      test('SessionExercise with replaced state round-trips through JSON', () {
        final rng = Random(307);
        for (var i = 0; i < iterations; i++) {
          final substitute = anySubstituteExercise(rng);
          final state = ExerciseState.replaced(substitute: substitute);
          final now = anyUtcDateTime(rng);
          final original = SessionExercise(
            id: anyUuidV4(rng),
            sessionId: anyUuidV4(rng),
            position: rng.nextInt(10),
            plannedExerciseIdInSnapshot: anyUuidV4(rng),
            state: state,
            executedSets: const [],
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          );

          final roundTripped = SessionExercise.fromJson(original.toJson());

          expect(roundTripped, equals(original));
          expect(roundTripped.state, isA<ReplacedState>());
          final replaced = roundTripped.state as ReplacedState;
          expect(replaced.substitute, equals(substitute));
        }
      });

      test('SubstituteExercise with metadata round-trips through JSON', () {
        final rng = Random(308);
        for (var i = 0; i < iterations; i++) {
          final measurementType = anyMeasurementType(rng);
          final original = SubstituteExercise(
            name: 'Cable Row',
            measurementType: measurementType,
            plannedValues: anyPlannedSetValuesForMeasurement(
              rng,
              measurementType,
            ),
            setCount: 1 + rng.nextInt(5),
            metadata: anyExerciseMetadata(rng),
          );

          final roundTripped = SubstituteExercise.fromJson(original.toJson());
          expect(roundTripped, equals(original));
        }
      });
    });
  });
}
