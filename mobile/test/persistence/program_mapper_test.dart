import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/mappers/program_mapper.dart';

void main() {
  final mapper = ProgramMapper();

  test('toRow(toDomain(row)) round-trips all fields', () {
    const row = Program(
      id: '11111111-1111-4111-8111-111111111111',
      name: 'Strength Block A',
      createdAtMs: 1700000000000,
      updatedAtMs: 1700000001000,
      schemaVersion: 1,
    );

    final domain = mapper.toDomain(row, [
      '22222222-2222-4222-8222-222222222222',
      '33333333-3333-4333-8333-333333333333',
    ]);
    final companion = mapper.toRow(domain);

    expect(companion.id.value, equals(row.id));
    expect(companion.name.value, equals(row.name));
    expect(companion.createdAtMs.value, equals(row.createdAtMs));
    expect(companion.updatedAtMs.value, equals(row.updatedAtMs));
    expect(companion.schemaVersion.value, equals(row.schemaVersion));
  });
}
