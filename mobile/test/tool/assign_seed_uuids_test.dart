import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/assign_seed_uuids.dart';

const _existingId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const _staleLockedId = 'deadbeef-dead-4ead-8ead-deadbeefdead';

List<Map<String, dynamic>> _catalogOf(String json) =>
    (jsonDecode(json) as List).cast<Map<String, dynamic>>();

List<String> _lockOf(String json) => (jsonDecode(json) as List).cast<String>();

void main() {
  group('assignSeedUuids', () {
    test('assigns a fresh id only to entries missing one', () {
      var counter = 0;
      final result = assignSeedUuids(
        catalogJson: jsonEncode([
          {'id': null, 'name': 'New One'},
          {'id': _existingId, 'name': 'Existing'},
        ]),
        lockJson: jsonEncode([_existingId]),
        generateId: () => 'generated-${counter++}',
      );

      final catalog = _catalogOf(result.catalogJson);
      expect(catalog[0]['id'], equals('generated-0'));
      expect(
        catalog[1]['id'],
        equals(_existingId),
        reason: 'an existing id must never be regenerated',
      );
      expect(result.assignedNames, equals(['New One']));
    });

    test('appends new ids to the lock without removing existing ones', () {
      final result = assignSeedUuids(
        catalogJson: jsonEncode([
          {'id': _existingId, 'name': 'Existing'},
          {'id': null, 'name': 'Fresh'},
        ]),
        // The lock already tracks a previously-shipped id.
        lockJson: jsonEncode([_existingId, _staleLockedId]),
        generateId: () => '11111111-1111-4111-8111-111111111111',
      );

      final lock = _lockOf(result.lockJson);
      expect(
        lock,
        containsAll([
          _existingId,
          _staleLockedId,
          '11111111-1111-4111-8111-111111111111',
        ]),
      );
      expect(
        lock.length,
        equals(3),
        reason: 'append-only: no locked id is dropped',
      );
    });

    test('is a no-op when every entry already has an id', () {
      final result = assignSeedUuids(
        catalogJson: jsonEncode([
          {'id': _existingId, 'name': 'Existing'},
        ]),
        lockJson: jsonEncode([_existingId]),
        generateId: () => fail('must not generate an id when none are missing'),
      );

      expect(result.assignedNames, isEmpty);
      expect(_catalogOf(result.catalogJson)[0]['id'], equals(_existingId));
      expect(_lockOf(result.lockJson), equals([_existingId]));
    });

    test('seeds the lock from scratch when there is no lock yet', () {
      var counter = 0;
      final result = assignSeedUuids(
        catalogJson: jsonEncode([
          {'id': null, 'name': 'A'},
          {'id': null, 'name': 'B'},
        ]),
        lockJson: null,
        generateId: () => 'id-${counter++}',
      );

      expect(result.assignedNames, equals(['A', 'B']));
      expect(_lockOf(result.lockJson), equals(['id-0', 'id-1']));
    });
  });
}
