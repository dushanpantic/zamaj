import 'dart:convert';

import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/canonical_seed_exercise.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/muscle_group.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';

/// Parses the embedded canonical exercise catalog JSON into validated
/// [CanonicalSeedExercise] entries.
///
/// Pure Dart (`dart:convert` only) so it stays usable from the offline
/// domain layer, the build-time integrity tests, and the launch seeder.
/// The catalog wire format is a top-level JSON array of entries, each:
///
/// ```json
/// {
///   "id": "<uuid-v4>",
///   "name": "Barbell Bench Press",
///   "measurementType": "repBased",
///   "prominence": "common",
///   "primaryMuscles": ["chest"],
///   "secondaryMuscles": ["triceps", "shoulders"],
///   "videoUrl": "https://...",   // optional
///   "cues": "Brace."             // optional
/// }
/// ```
///
/// Throws [DeserializationError] for shape/enum problems and [ValidationError]
/// for value invariants (id format, disjoint muscles, duplicate ids).
abstract final class CanonicalSeedCatalog {
  static List<CanonicalSeedExercise> parse(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      throw const DeserializationError(
        field: 'root',
        message: 'catalog must be a top-level JSON array',
      );
    }

    final entries = <CanonicalSeedExercise>[];
    final seenIds = <String>{};
    for (var index = 0; index < decoded.length; index++) {
      final raw = decoded[index];
      if (raw is! Map<String, dynamic>) {
        throw DeserializationError(
          field: 'entry',
          message: 'entry $index must be a JSON object',
        );
      }
      final entry = _parseEntry(raw, index);
      if (!seenIds.add(entry.id)) {
        throw ValidationError(
          entityId: entry.id,
          invariant: 'duplicate_seed_id',
          message: 'duplicate seed id "${entry.id}" at entry $index',
        );
      }
      entries.add(entry);
    }
    return entries;
  }

  static CanonicalSeedExercise _parseEntry(
    Map<String, dynamic> raw,
    int index,
  ) {
    return CanonicalSeedExercise(
      id: _requireString(raw, 'id', index),
      name: _requireString(raw, 'name', index),
      measurementType: MeasurementType.fromJson({
        'type': _requireString(raw, 'measurementType', index),
      }),
      prominence: Prominence.fromJson(_requireString(raw, 'prominence', index)),
      primaryMuscles: _muscleList(raw, 'primaryMuscles', index),
      secondaryMuscles: _muscleList(raw, 'secondaryMuscles', index),
      videoUrl: _optionalString(raw, 'videoUrl', index),
      cues: _optionalString(raw, 'cues', index),
    );
  }

  static String _requireString(Map<String, dynamic> raw, String key, int i) {
    final value = raw[key];
    if (value is! String) {
      throw DeserializationError(
        field: key,
        message: 'entry $i: "$key" must be a string, got ${value.runtimeType}',
      );
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> raw, String key, int i) {
    final value = raw[key];
    if (value == null) return null;
    if (value is! String) {
      throw DeserializationError(
        field: key,
        message: 'entry $i: "$key" must be a string or absent',
      );
    }
    return value;
  }

  static List<MuscleGroup> _muscleList(
    Map<String, dynamic> raw,
    String key,
    int i,
  ) {
    final value = raw[key];
    if (value == null) return const [];
    if (value is! List) {
      throw DeserializationError(
        field: key,
        message: 'entry $i: "$key" must be a JSON array',
      );
    }
    return value.map((m) {
      if (m is! String) {
        throw DeserializationError(
          field: key,
          message: 'entry $i: "$key" entries must be strings',
        );
      }
      return MuscleGroup.fromJson(m);
    }).toList();
  }
}
