import 'package:zamaj/modules/domain/errors.dart';

final class PresentedMessage {
  const PresentedMessage({required this.title, required this.body});

  final String title;
  final String body;
}

abstract final class DomainErrorPresenter {
  static PresentedMessage present(DomainError error) {
    return switch (error) {
      ValidationError(:final entityId, :final invariant, :final message) =>
        PresentedMessage(
          title: 'Invalid value',
          body: '$invariant ($entityId): $message',
        ),
      NotFoundError(:final entityType, :final id) => PresentedMessage(
        title: '$entityType not found',
        body: id,
      ),
      ImmutabilityError(:final sessionId, :final message) => PresentedMessage(
        title: 'Historical record protected',
        body: '$message (session $sessionId)',
      ),
      OrderingError(
        :final sessionExerciseId,
        :final currentState,
        :final message,
      ) =>
        PresentedMessage(
          title: 'Out-of-order edit',
          body: '$message [$sessionExerciseId / $currentState]',
        ),
      VersionMismatchError(:final persisted, :final expected) =>
        PresentedMessage(
          title: 'Database newer than app',
          body: 'persisted v$persisted > expected v$expected',
        ),
      DeserializationError(
        :final field,
        :final discriminator,
        :final message,
      ) =>
        PresentedMessage(
          title: 'Data could not be read',
          body:
              '$field${discriminator == null ? '' : '/$discriminator'}: $message',
        ),
    };
  }
}
