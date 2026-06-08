import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/canonical_seed_exercise.dart';
import 'package:zamaj/modules/domain/models/library_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/library_source.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/prominence.dart';
import 'package:zamaj/modules/domain/repositories/exercise_library_repository.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/database/datetime_utils.dart';
import 'package:zamaj/modules/persistence/database/timestamp_oracle.dart';
import 'package:zamaj/modules/persistence/mappers/library_exercise_mapper.dart';

class DriftExerciseLibraryRepository implements ExerciseLibraryRepository {
  DriftExerciseLibraryRepository({
    required AppDatabase db,
    Clock clock = const Clock(),
  }) : _db = db,
       _clock = clock,
       _timestamps = TimestampOracle(clock);

  final AppDatabase _db;
  final Clock _clock;
  final TimestampOracle _timestamps;
  final _uuid = const Uuid();
  final _mapper = LibraryExerciseMapper();

  @override
  Future<domain.LibraryExercise> create({
    required String name,
    required MeasurementType measurementType,
    String? videoUrl,
    String? cues,
  }) async {
    final id = _uuid.v4();
    final now = _clock.now().toUtc();
    final measurementJson = measurementType.toJson();
    await _db
        .into(_db.libraryExercises)
        .insert(
          LibraryExercisesCompanion.insert(
            id: id,
            name: name,
            nameLower: LibraryExerciseMapper.normalize(name),
            measurementTypeDiscriminator: measurementJson['type'] as String,
            measurementTypePayloadJson: CanonicalJson.encode(measurementJson),
            videoUrl: Value(videoUrl),
            cues: Value(cues),
            createdAtMs: utcToMs(now),
            updatedAtMs: utcToMs(now),
            schemaVersion: SchemaVersions.domain,
          ),
        );
    return (await get(id))!;
  }

  @override
  Future<int> seedCanonical(List<CanonicalSeedExercise> entries) async {
    if (entries.isEmpty) return 0;
    final now = _clock.now().toUtc();
    return _db.transaction(() async {
      // Insert is keyed by id: skip entries whose id already exists so a
      // user edit to a previously-seeded row is never clobbered. The
      // insertOrIgnore mode is a belt-and-suspenders guard on the same key.
      final ids = entries.map((e) => e.id).toList();
      final existing = await (_db.select(
        _db.libraryExercises,
      )..where((t) => t.id.isIn(ids))).get();
      final existingIds = existing.map((r) => r.id).toSet();
      final toInsert = entries
          .where((e) => !existingIds.contains(e.id))
          .toList();
      if (toInsert.isEmpty) return 0;

      await _db.batch((batch) {
        for (final entry in toInsert) {
          final measurementJson = entry.measurementType.toJson();
          batch.insert(
            _db.libraryExercises,
            LibraryExercisesCompanion.insert(
              id: entry.id,
              name: entry.name,
              nameLower: LibraryExerciseMapper.normalize(entry.name),
              measurementTypeDiscriminator: measurementJson['type'] as String,
              measurementTypePayloadJson: CanonicalJson.encode(measurementJson),
              source: Value(LibrarySource.canonicalSeed.toJson()),
              prominence: Value(entry.prominence.toJson()),
              primaryMusclesJson: Value(
                LibraryExerciseMapper.encodeMuscles(entry.primaryMuscles),
              ),
              secondaryMusclesJson: Value(
                LibraryExerciseMapper.encodeMuscles(entry.secondaryMuscles),
              ),
              videoUrl: Value(entry.videoUrl),
              cues: Value(entry.cues),
              createdAtMs: utcToMs(now),
              updatedAtMs: utcToMs(now),
              schemaVersion: SchemaVersions.domain,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
      return toInsert.length;
    });
  }

  @override
  Future<domain.LibraryExercise?> get(String id) async {
    final row = await (_db.select(
      _db.libraryExercises,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _mapper.toDomain(row);
  }

  @override
  Future<List<domain.LibraryExercise>> list({
    bool includeArchived = false,
    MeasurementType? measurementType,
    String? nameQuery,
  }) async {
    final query = _db.select(_db.libraryExercises);

    if (!includeArchived) {
      query.where((t) => t.archivedAtMs.isNull());
    }

    if (measurementType != null) {
      final discriminator = measurementType.toJson()['type'] as String;
      query.where((t) => t.measurementTypeDiscriminator.equals(discriminator));
    }

    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      final needle = '%${nameQuery.trim().toLowerCase()}%';
      query.where((t) => t.nameLower.like(needle));
    }

    query.orderBy([_commonFirst, (t) => OrderingTerm.asc(t.nameLower)]);
    final rows = await query.get();
    return rows.map(_mapper.toDomain).toList();
  }

  /// Orders [Prominence.common] entries ahead of [Prominence.specialized] via
  /// an explicit rank (common → 0, specialized → 1), so the tier ordering is
  /// the stated intent — not a coincidence of how the discriminators happen to
  /// sort alphabetically.
  static OrderingTerm _commonFirst($LibraryExercisesTable t) =>
      OrderingTerm.asc(t.prominence.equals(Prominence.specialized.toJson()));

  @override
  Future<domain.LibraryExercise> update(domain.LibraryExercise entry) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.libraryExercises,
      )..where((t) => t.id.equals(entry.id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'LibraryExercise', id: entry.id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      final measurementJson = entry.measurementType.toJson();
      await (_db.update(
        _db.libraryExercises,
      )..where((t) => t.id.equals(entry.id))).write(
        LibraryExercisesCompanion(
          name: Value(entry.name),
          nameLower: Value(LibraryExerciseMapper.normalize(entry.name)),
          measurementTypeDiscriminator: Value(
            measurementJson['type'] as String,
          ),
          measurementTypePayloadJson: Value(
            CanonicalJson.encode(measurementJson),
          ),
          videoUrl: Value(entry.videoUrl),
          cues: Value(entry.cues),
          archivedAtMs: Value(entry.archivedAt?.millisecondsSinceEpoch),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );
      return (await get(entry.id))!;
    });
  }

  @override
  Future<domain.LibraryExercise> archive(String id) =>
      _setArchivedAt(id, _clock.now().toUtc());

  @override
  Future<domain.LibraryExercise> unarchive(String id) =>
      _setArchivedAt(id, null);

  Future<domain.LibraryExercise> _setArchivedAt(
    String id,
    DateTime? archivedAt,
  ) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.libraryExercises,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'LibraryExercise', id: id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      await (_db.update(
        _db.libraryExercises,
      )..where((t) => t.id.equals(id))).write(
        LibraryExercisesCompanion(
          archivedAtMs: Value(archivedAt?.millisecondsSinceEpoch),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );
      return (await get(id))!;
    });
  }

  @override
  Future<domain.LibraryExercise?> findByNormalizedName(String name) async {
    final normalized = LibraryExerciseMapper.normalize(name);
    final rows =
        await (_db.select(_db.libraryExercises)
              ..where((t) => t.nameLower.equals(normalized))
              ..orderBy([
                (t) => OrderingTerm.asc(t.archivedAtMs),
                (t) => OrderingTerm.asc(t.createdAtMs),
              ])
              ..limit(1))
            .get();
    if (rows.isEmpty) return null;
    return _mapper.toDomain(rows.first);
  }
}
