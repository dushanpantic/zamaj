import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';

part 'session_snapshot.freezed.dart';
part 'session_snapshot.g.dart';

@freezed
abstract class SessionSnapshot with _$SessionSnapshot {
  SessionSnapshot._() {
    final recomputedJson = CanonicalJson.encode(workoutDay.toJson());
    if (canonicalJson != recomputedJson) {
      throw ValidationError(
        entityId: sha256Hash,
        invariant: 'snapshot_canonical_json_mismatch',
        message:
            'canonicalJson does not match CanonicalJson.encode(workoutDay.toJson())',
      );
    }
    final recomputedHash = CanonicalJson.sha256Hex(canonicalJson);
    if (sha256Hash != recomputedHash) {
      throw ValidationError(
        entityId: sha256Hash,
        invariant: 'snapshot_hash_mismatch',
        message:
            'sha256Hash does not match sha256(canonicalJson): '
            'expected $recomputedHash',
      );
    }
  }

  factory SessionSnapshot({
    required WorkoutDay workoutDay,
    required String canonicalJson,
    required String sha256Hash,
    required DateTime capturedAt,
    required int schemaVersion,
  }) = _SessionSnapshot;

  factory SessionSnapshot.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$SessionSnapshotFromJson(json),
        json,
        'SessionSnapshot',
      );

  /// Creates a [SessionSnapshot] from a [WorkoutDay], computing the canonical
  /// JSON and hash automatically.
  static SessionSnapshot capture({
    required WorkoutDay workoutDay,
    required DateTime capturedAt,
    required int schemaVersion,
  }) {
    final json = CanonicalJson.encode(workoutDay.toJson());
    final hash = CanonicalJson.sha256Hex(json);
    return SessionSnapshot(
      workoutDay: workoutDay,
      canonicalJson: json,
      sha256Hash: hash,
      capturedAt: capturedAt,
      schemaVersion: schemaVersion,
    );
  }
}
