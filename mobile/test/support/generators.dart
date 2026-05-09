import 'dart:math';

import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

String anyUuidV4(Random rng) {
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final b = bytes.map(hex).toList();
  return '${b[0]}${b[1]}${b[2]}${b[3]}'
      '-${b[4]}${b[5]}'
      '-${b[6]}${b[7]}'
      '-${b[8]}${b[9]}'
      '-${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
}

DateTime anyUtcDateTime(Random rng) {
  final minMs = DateTime(2000).millisecondsSinceEpoch;
  final maxMs = DateTime(2100).millisecondsSinceEpoch;
  final ms = minMs + rng.nextInt(maxMs - minMs);
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}

MeasurementType anyMeasurementType(Random rng) {
  return rng.nextBool()
      ? const MeasurementType.repBased()
      : const MeasurementType.timeBased();
}

ExerciseGroupKind anyExerciseGroupKind(Random rng) {
  return rng.nextBool()
      ? const ExerciseGroupKind.single()
      : const ExerciseGroupKind.superset();
}

ExerciseMetadata anyExerciseMetadata(Random rng) {
  final hasNotes = rng.nextBool();
  final hasVideo = rng.nextBool();
  return ExerciseMetadata(
    notes: hasNotes ? _anyString(rng, maxLen: 80) : null,
    videoUrl: hasVideo ? 'https://example.com/${anyUuidV4(rng)}' : null,
  );
}

SubstituteExercise anySubstituteExercise(Random rng) {
  final mt = anyMeasurementType(rng);
  return SubstituteExercise(
    name: _anyString(rng, maxLen: 40),
    measurementType: mt,
    metadata: rng.nextBool() ? anyExerciseMetadata(rng) : null,
  );
}

ExerciseState anyExerciseState(Random rng) {
  switch (rng.nextInt(4)) {
    case 0:
      return const ExerciseState.unfinished();
    case 1:
      return const ExerciseState.completed();
    case 2:
      return const ExerciseState.skipped();
    default:
      return ExerciseState.replaced(substitute: anySubstituteExercise(rng));
  }
}

PlannedSetValues anyPlannedSetValues(Random rng) {
  if (rng.nextBool()) {
    return PlannedSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    );
  }
  return PlannedSetValues.timeBased(durationSeconds: rng.nextInt(300));
}

PlannedSetValues anyPlannedSetValuesForMeasurement(
  Random rng,
  MeasurementType mt,
) {
  return mt.when(
    repBased: () => PlannedSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    ),
    timeBased: () =>
        PlannedSetValues.timeBased(durationSeconds: rng.nextInt(300)),
  );
}

ActualSetValues anyActualSetValues(Random rng) {
  if (rng.nextBool()) {
    return ActualSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    );
  }
  return ActualSetValues.timeBased(durationSeconds: rng.nextInt(300));
}

ActualSetValues anyActualSetValuesForMeasurement(
  Random rng,
  MeasurementType mt,
) {
  return mt.when(
    repBased: () => ActualSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    ),
    timeBased: () =>
        ActualSetValues.timeBased(durationSeconds: rng.nextInt(300)),
  );
}

double _anyWeightKg(Random rng) {
  final halfKgs = rng.nextInt(401);
  return halfKgs * 0.5;
}

String _anyString(Random rng, {required int maxLen}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  final len = 1 + rng.nextInt(maxLen);
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}
