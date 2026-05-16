import 'package:equatable/equatable.dart';

sealed class RecentSessionsEvent extends Equatable {
  const RecentSessionsEvent();

  @override
  List<Object?> get props => const [];
}

final class RecentSessionsOpened extends RecentSessionsEvent {
  const RecentSessionsOpened(this.programId);

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class RecentSessionsRetried extends RecentSessionsEvent {
  const RecentSessionsRetried();
}

final class RecentSessionsRefreshed extends RecentSessionsEvent {
  const RecentSessionsRefreshed();
}
