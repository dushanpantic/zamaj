import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/models/session_history_item.dart';

sealed class RecentSessionsState extends Equatable {
  const RecentSessionsState();

  @override
  List<Object?> get props => const [];
}

final class RecentSessionsInitial extends RecentSessionsState {
  const RecentSessionsInitial();
}

final class RecentSessionsLoading extends RecentSessionsState {
  const RecentSessionsLoading(this.programId);

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class RecentSessionsProgramNotFound extends RecentSessionsState {
  const RecentSessionsProgramNotFound(this.programId);

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class RecentSessionsFailure extends RecentSessionsState {
  const RecentSessionsFailure({required this.programId, required this.error});

  final String programId;
  final DomainError error;

  @override
  List<Object?> get props => [programId, error];
}

final class RecentSessionsLoaded extends RecentSessionsState {
  const RecentSessionsLoaded({
    required this.programId,
    required this.programName,
    required this.items,
    required this.sessionsById,
    required this.weekSessions,
    required this.window,
    required this.referenceNow,
  });

  final String programId;
  final String programName;

  /// All completed sessions across the program, newest first. Already
  /// flagged with `isInThisWeek`.
  final List<SessionHistoryItem> items;

  /// Every completed [Session] keyed by id, so the screen can render an
  /// export preview for any tile without a round-trip to the repository.
  final Map<String, Session> sessionsById;

  /// Subset of completed [Session]s whose `endedAt` falls inside [window],
  /// ordered chronologically — pre-sorted so the week formatter stays pure
  /// w.r.t. ordering.
  final List<Session> weekSessions;

  final TrainingWeek window;
  final DateTime referenceNow;

  bool get hasWeekSessions => weekSessions.isNotEmpty;

  @override
  List<Object?> get props => [
    programId,
    programName,
    items,
    sessionsById,
    weekSessions,
    window,
    referenceNow,
  ];
}
