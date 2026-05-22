import 'package:drift/drift.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/persistence/database/migrations.dart';
import 'package:zamaj/modules/persistence/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Programs,
    ProgramWorkoutDays,
    WorkoutDays,
    ExerciseGroups,
    Exercises,
    WorkoutSets,
    Sessions,
    SessionExercises,
    ExecutedSets,
    SessionNotes,
    ExtraWorkItems,
    LibraryExercises,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => SchemaVersions.drift;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: AppMigrations.onUpgrade,
    beforeOpen: (details) async {
      if (details.versionBefore != null &&
          details.versionBefore! > schemaVersion) {
        throw VersionMismatchError(
          persisted: details.versionBefore!,
          expected: schemaVersion,
        );
      }
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
