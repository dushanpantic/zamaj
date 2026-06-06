import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class SessionDetailEvent extends Equatable {
  const SessionDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// The lifter corrected a logged set's actual values from the review screen.
/// Routed to [SessionFlowEngine.updateExecutedSet]; the watch stream then
/// re-emits the fresh session.
final class SessionDetailSetValueEdited extends SessionDetailEvent {
  const SessionDetailSetValueEdited({
    required this.executedSetId,
    required this.actualValues,
  });

  final String executedSetId;
  final ActualSetValues actualValues;

  @override
  List<Object?> get props => [executedSetId, actualValues];
}

/// Internal: the watched session changed in the repository (or was re-emitted
/// after an edit). Carries the fresh [Session] to re-render from.
final class SessionDetailSessionUpdated extends SessionDetailEvent {
  const SessionDetailSessionUpdated(this.session);

  final Session session;

  @override
  List<Object?> get props => [session];
}
