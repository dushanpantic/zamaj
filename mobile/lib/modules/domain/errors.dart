import 'package:meta/meta.dart';

@immutable
sealed class DomainError implements Exception {
  const DomainError(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class ValidationError extends DomainError {
  const ValidationError({
    required this.entityId,
    required this.invariant,
    required String message,
  }) : super(message);

  final String entityId;
  final String invariant;
}

final class ImmutabilityError extends DomainError {
  const ImmutabilityError({required this.sessionId, required String message})
    : super(message);

  final String sessionId;
}

final class OrderingError extends DomainError {
  const OrderingError({
    required this.sessionExerciseId,
    required this.currentState,
    required String message,
  }) : super(message);

  final String sessionExerciseId;
  // TODO(exercise-state-typing): replace String with ExerciseState once task 4 lands.
  final String currentState;
}

final class VersionMismatchError extends DomainError {
  const VersionMismatchError({required this.persisted, required this.expected})
    : super('Persisted schema v$persisted > expected v$expected');

  final int persisted;
  final int expected;
}

final class DeserializationError extends DomainError {
  const DeserializationError({
    required this.field,
    this.discriminator,
    required String message,
  }) : super(message);

  final String field;
  final String? discriminator;
}

final class NotFoundError extends DomainError {
  const NotFoundError({required this.entityType, required this.id})
    : super('$entityType $id not found');

  final String entityType;
  final String id;
}
