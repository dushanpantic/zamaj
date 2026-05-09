import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';

void main() {
  group('ValidationError', () {
    test('carries entityId, invariant, and message', () {
      const error = ValidationError(
        entityId: 'abc-123',
        invariant: 'set.weight.negative',
        message: 'Weight must be non-negative',
      );

      expect(error.entityId, 'abc-123');
      expect(error.invariant, 'set.weight.negative');
      expect(error.message, 'Weight must be non-negative');
    });

    test('is a DomainError and Exception', () {
      const error = ValidationError(
        entityId: '<new>',
        invariant: 'group.cardinality.single',
        message: 'Single group must have exactly one exercise',
      );

      expect(error, isA<DomainError>());
      expect(error, isA<Exception>());
    });

    test('toString includes runtimeType and message', () {
      const error = ValidationError(
        entityId: 'x',
        invariant: 'set.reps.negative',
        message: 'Reps must be non-negative',
      );

      expect(error.toString(), contains('ValidationError'));
      expect(error.toString(), contains('Reps must be non-negative'));
    });
  });

  group('ImmutabilityError', () {
    test('carries sessionId and message', () {
      const error = ImmutabilityError(
        sessionId: 'session-uuid',
        message: 'Cannot mutate snapshot for session session-uuid',
      );

      expect(error.sessionId, 'session-uuid');
      expect(error.message, 'Cannot mutate snapshot for session session-uuid');
    });

    test('is a DomainError and Exception', () {
      const error = ImmutabilityError(sessionId: 's1', message: 'immutable');

      expect(error, isA<DomainError>());
      expect(error, isA<Exception>());
    });

    test('toString includes runtimeType and message', () {
      const error = ImmutabilityError(
        sessionId: 's1',
        message: 'snapshot is immutable',
      );

      expect(error.toString(), contains('ImmutabilityError'));
      expect(error.toString(), contains('snapshot is immutable'));
    });
  });

  group('OrderingError', () {
    test('carries sessionExerciseId, currentState, and message', () {
      const error = OrderingError(
        sessionExerciseId: 'se-uuid',
        currentState: 'completed',
        message: 'Cannot reorder a completed exercise',
      );

      expect(error.sessionExerciseId, 'se-uuid');
      expect(error.currentState, 'completed');
      expect(error.message, 'Cannot reorder a completed exercise');
    });

    test('is a DomainError and Exception', () {
      const error = OrderingError(
        sessionExerciseId: 'se-1',
        currentState: 'skipped',
        message: 'locked',
      );

      expect(error, isA<DomainError>());
      expect(error, isA<Exception>());
    });

    test('toString includes runtimeType and message', () {
      const error = OrderingError(
        sessionExerciseId: 'se-1',
        currentState: 'replaced',
        message: 'position is locked',
      );

      expect(error.toString(), contains('OrderingError'));
      expect(error.toString(), contains('position is locked'));
    });
  });

  group('VersionMismatchError', () {
    test('auto-composes message from persisted and expected', () {
      const error = VersionMismatchError(persisted: 3, expected: 1);

      expect(error.persisted, 3);
      expect(error.expected, 1);
      expect(error.message, 'Persisted schema v3 > expected v1');
    });

    test('is a DomainError and Exception', () {
      const error = VersionMismatchError(persisted: 2, expected: 1);

      expect(error, isA<DomainError>());
      expect(error, isA<Exception>());
    });

    test('toString includes runtimeType and composed message', () {
      const error = VersionMismatchError(persisted: 5, expected: 2);

      expect(error.toString(), contains('VersionMismatchError'));
      expect(error.toString(), contains('v5'));
      expect(error.toString(), contains('v2'));
    });
  });

  group('DeserializationError', () {
    test('carries field, optional discriminator, and message', () {
      const error = DeserializationError(
        field: 'measurementType',
        discriminator: 'unknownVariant',
        message: 'Unknown discriminator: unknownVariant',
      );

      expect(error.field, 'measurementType');
      expect(error.discriminator, 'unknownVariant');
      expect(error.message, 'Unknown discriminator: unknownVariant');
    });

    test('discriminator is nullable', () {
      const error = DeserializationError(
        field: 'schemaVersion',
        message: 'Missing required field: schemaVersion',
      );

      expect(error.field, 'schemaVersion');
      expect(error.discriminator, isNull);
    });

    test('is a DomainError and Exception', () {
      const error = DeserializationError(field: 'type', message: 'bad');

      expect(error, isA<DomainError>());
      expect(error, isA<Exception>());
    });

    test('toString includes runtimeType and message', () {
      const error = DeserializationError(
        field: 'sessionSnapshot',
        discriminator: 'sha256Hash',
        message: 'Hash mismatch',
      );

      expect(error.toString(), contains('DeserializationError'));
      expect(error.toString(), contains('Hash mismatch'));
    });
  });

  group('NotFoundError', () {
    test('auto-composes message from entityType and id', () {
      const error = NotFoundError(entityType: 'Program', id: 'prog-uuid');

      expect(error.entityType, 'Program');
      expect(error.id, 'prog-uuid');
      expect(error.message, 'Program prog-uuid not found');
    });

    test('is a DomainError and Exception', () {
      const error = NotFoundError(entityType: 'WorkoutDay', id: 'wd-1');

      expect(error, isA<DomainError>());
      expect(error, isA<Exception>());
    });

    test('toString includes runtimeType and composed message', () {
      const error = NotFoundError(entityType: 'Session', id: 's-42');

      expect(error.toString(), contains('NotFoundError'));
      expect(error.toString(), contains('Session s-42 not found'));
    });
  });

  group('DomainError sealed hierarchy', () {
    test('all subclasses are exhaustively matchable', () {
      final errors = <DomainError>[
        const ValidationError(entityId: 'e1', invariant: 'test', message: 'v'),
        const ImmutabilityError(sessionId: 's1', message: 'i'),
        const OrderingError(
          sessionExerciseId: 'se1',
          currentState: 'completed',
          message: 'o',
        ),
        const VersionMismatchError(persisted: 2, expected: 1),
        const DeserializationError(field: 'f', message: 'd'),
        const NotFoundError(entityType: 'T', id: 'id'),
      ];

      for (final error in errors) {
        final matched = switch (error) {
          ValidationError() => 'validation',
          ImmutabilityError() => 'immutability',
          OrderingError() => 'ordering',
          VersionMismatchError() => 'version',
          DeserializationError() => 'deserialization',
          NotFoundError() => 'notFound',
        };
        expect(matched, isNotEmpty);
      }
    });
  });
}
