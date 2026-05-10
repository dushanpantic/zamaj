import 'package:drift/drift.dart';
import 'package:zamaj/modules/domain/models/program.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart';

class ProgramMapper {
  domain.Program toDomain(Program row, List<String> workoutDayIds) {
    return domain.Program(
      id: row.id,
      name: row.name,
      workoutDayIds: workoutDayIds,
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

  ProgramsCompanion toRow(domain.Program domain) {
    return ProgramsCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      createdAtMs: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(domain.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(domain.schemaVersion),
    );
  }
}
