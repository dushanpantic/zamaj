import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_note.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

import '../support/generators.dart';

Map<String, dynamic> _dropField(Map<String, dynamic> json, String field) {
  final copy = Map<String, dynamic>.from(json);
  copy.remove(field);
  return copy;
}

void _assertDeserializationError(void Function() fn, String expectedField) {
  try {
    fn();
    fail('Expected DeserializationError but no exception was thrown');
  } on DeserializationError catch (e) {
    expect(
      e.field,
      equals(expectedField),
      reason: 'DeserializationError.field should name the offending field',
    );
  }
}

void main() {
  const iterations = 100;
  final rng = Random(1000);

  group('P10 – Typed deserialization error naming (aggregates)', () {
    group('Program', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyProgram(rng);
          _assertDeserializationError(
            () => Program.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing name names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyProgram(rng);
          _assertDeserializationError(
            () => Program.fromJson(_dropField(v.toJson(), 'name')),
            'name',
          );
        }
      });
    });

    group('WorkoutDay', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyWorkoutDay(rng);
          _assertDeserializationError(
            () => WorkoutDay.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing name names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyWorkoutDay(rng);
          _assertDeserializationError(
            () => WorkoutDay.fromJson(_dropField(v.toJson(), 'name')),
            'name',
          );
        }
      });
    });

    group('ExerciseGroup', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExerciseGroup(rng);
          _assertDeserializationError(
            () => ExerciseGroup.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing kind names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExerciseGroup(rng);
          _assertDeserializationError(
            () => ExerciseGroup.fromJson(_dropField(v.toJson(), 'kind')),
            'kind',
          );
        }
      });
    });

    group('Exercise', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExercise(rng);
          _assertDeserializationError(
            () => Exercise.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing measurementType names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExercise(rng);
          _assertDeserializationError(
            () => Exercise.fromJson(_dropField(v.toJson(), 'measurementType')),
            'measurementType',
          );
        }
      });
    });

    group('WorkoutSet', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final mt = anyMeasurementType(rng);
          final v = anyWorkoutSet(rng, mt);
          _assertDeserializationError(
            () => WorkoutSet.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing plannedValues names the field', () {
        for (var i = 0; i < iterations; i++) {
          final mt = anyMeasurementType(rng);
          final v = anyWorkoutSet(rng, mt);
          _assertDeserializationError(
            () => WorkoutSet.fromJson(_dropField(v.toJson(), 'plannedValues')),
            'plannedValues',
          );
        }
      });
    });

    group('SubstituteExercise', () {
      test('missing name names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySubstituteExercise(rng);
          _assertDeserializationError(
            () => SubstituteExercise.fromJson(_dropField(v.toJson(), 'name')),
            'name',
          );
        }
      });

      test('missing measurementType names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySubstituteExercise(rng);
          _assertDeserializationError(
            () => SubstituteExercise.fromJson(
              _dropField(v.toJson(), 'measurementType'),
            ),
            'measurementType',
          );
        }
      });
    });

    group('ExecutedSet', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final mt = anyMeasurementType(rng);
          final v = anyExecutedSet(rng, mt);
          _assertDeserializationError(
            () => ExecutedSet.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing actualValues names the field', () {
        for (var i = 0; i < iterations; i++) {
          final mt = anyMeasurementType(rng);
          final v = anyExecutedSet(rng, mt);
          _assertDeserializationError(
            () => ExecutedSet.fromJson(_dropField(v.toJson(), 'actualValues')),
            'actualValues',
          );
        }
      });
    });

    group('SessionExercise', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionExercise(rng);
          _assertDeserializationError(
            () => SessionExercise.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing state names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionExercise(rng);
          _assertDeserializationError(
            () => SessionExercise.fromJson(_dropField(v.toJson(), 'state')),
            'state',
          );
        }
      });

      test('missing plannedExerciseIdInSnapshot names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionExercise(rng);
          _assertDeserializationError(
            () => SessionExercise.fromJson(
              _dropField(v.toJson(), 'plannedExerciseIdInSnapshot'),
            ),
            'plannedExerciseIdInSnapshot',
          );
        }
      });
    });

    group('SessionNote', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionNote(rng);
          _assertDeserializationError(
            () => SessionNote.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing body names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionNote(rng);
          _assertDeserializationError(
            () => SessionNote.fromJson(_dropField(v.toJson(), 'body')),
            'body',
          );
        }
      });
    });

    group('ExtraWork', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExtraWork(rng);
          _assertDeserializationError(
            () => ExtraWork.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing body names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExtraWork(rng);
          _assertDeserializationError(
            () => ExtraWork.fromJson(_dropField(v.toJson(), 'body')),
            'body',
          );
        }
      });
    });

    group('SessionSnapshot', () {
      test('missing workoutDay names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionSnapshot(rng);
          _assertDeserializationError(
            () =>
                SessionSnapshot.fromJson(_dropField(v.toJson(), 'workoutDay')),
            'workoutDay',
          );
        }
      });

      test('missing canonicalJson names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionSnapshot(rng);
          _assertDeserializationError(
            () => SessionSnapshot.fromJson(
              _dropField(v.toJson(), 'canonicalJson'),
            ),
            'canonicalJson',
          );
        }
      });

      test('missing sha256Hash names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySessionSnapshot(rng);
          _assertDeserializationError(
            () =>
                SessionSnapshot.fromJson(_dropField(v.toJson(), 'sha256Hash')),
            'sha256Hash',
          );
        }
      });
    });

    group('Session', () {
      test('missing id names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySession(rng);
          _assertDeserializationError(
            () => Session.fromJson(_dropField(v.toJson(), 'id')),
            'id',
          );
        }
      });

      test('missing snapshot names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySession(rng);
          _assertDeserializationError(
            () => Session.fromJson(_dropField(v.toJson(), 'snapshot')),
            'snapshot',
          );
        }
      });

      test('missing workoutDayId names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySession(rng);
          _assertDeserializationError(
            () => Session.fromJson(_dropField(v.toJson(), 'workoutDayId')),
            'workoutDayId',
          );
        }
      });
    });
  });
}
