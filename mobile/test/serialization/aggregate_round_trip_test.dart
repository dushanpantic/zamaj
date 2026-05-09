import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
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

void main() {
  const iterations = 100;
  final rng = Random(900);

  group('P9 – JSON round-trip (aggregates)', () {
    test('Program round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyProgram(rng);
        expect(Program.fromJson(v.toJson()), equals(v));
      }
    });

    test('WorkoutDay round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyWorkoutDay(rng);
        expect(WorkoutDay.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExerciseGroup round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExerciseGroup(rng);
        expect(ExerciseGroup.fromJson(v.toJson()), equals(v));
      }
    });

    test('Exercise round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExercise(rng);
        expect(Exercise.fromJson(v.toJson()), equals(v));
      }
    });

    test('WorkoutSet round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final mt = anyMeasurementType(rng);
        final v = anyWorkoutSet(rng, mt);
        expect(WorkoutSet.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExerciseMetadata round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExerciseMetadata(rng);
        expect(ExerciseMetadata.fromJson(v.toJson()), equals(v));
      }
    });

    test('SubstituteExercise round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anySubstituteExercise(rng);
        expect(SubstituteExercise.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExecutedSet round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final mt = anyMeasurementType(rng);
        final v = anyExecutedSet(rng, mt);
        expect(ExecutedSet.fromJson(v.toJson()), equals(v));
      }
    });

    test('SessionExercise round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anySessionExercise(rng);
        expect(SessionExercise.fromJson(v.toJson()), equals(v));
      }
    });

    test('SessionNote round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anySessionNote(rng);
        expect(SessionNote.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExtraWork round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExtraWork(rng);
        expect(ExtraWork.fromJson(v.toJson()), equals(v));
      }
    });

    test('SessionSnapshot round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anySessionSnapshot(rng);
        expect(SessionSnapshot.fromJson(v.toJson()), equals(v));
      }
    });

    test('Session round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anySession(rng);
        expect(Session.fromJson(v.toJson()), equals(v));
      }
    });
  });
}
