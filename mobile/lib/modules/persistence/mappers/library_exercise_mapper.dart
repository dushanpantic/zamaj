import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/library_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

class LibraryExerciseMapper {
  domain.LibraryExercise toDomain(LibraryExercise row) {
    final measurementType = MeasurementType.fromJson(
      jsonDecode(row.measurementTypePayloadJson) as Map<String, dynamic>,
    );
    return domain.LibraryExercise(
      id: row.id,
      name: row.name,
      measurementType: measurementType,
      videoUrl: row.videoUrl,
      cues: row.cues,
      archivedAt: row.archivedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.archivedAtMs!, isUtc: true),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  LibraryExercisesCompanion toRow(domain.LibraryExercise entry) {
    final measurementJson = entry.measurementType.toJson();
    return LibraryExercisesCompanion(
      id: Value(entry.id),
      name: Value(entry.name),
      nameLower: Value(_normalize(entry.name)),
      measurementTypeDiscriminator: Value(measurementJson['type'] as String),
      measurementTypePayloadJson: Value(CanonicalJson.encode(measurementJson)),
      videoUrl: Value(entry.videoUrl),
      cues: Value(entry.cues),
      archivedAtMs: Value(entry.archivedAt?.millisecondsSinceEpoch),
      createdAtMs: Value(entry.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(entry.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(entry.schemaVersion),
    );
  }

  static String normalize(String name) => _normalize(name);

  static String _normalize(String name) => name.trim().toLowerCase();
}
