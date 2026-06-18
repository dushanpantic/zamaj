import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

sealed class SessionDetailState extends Equatable {
  const SessionDetailState();

  @override
  List<Object?> get props => const [];
}

/// The review screen is always reached with an already-hydrated [Session], so
/// there is no loading or failure state — the bloc starts loaded and re-emits
/// as the watched session changes.
final class SessionDetailLoaded extends SessionDetailState {
  const SessionDetailLoaded({
    required this.session,
    required this.groups,
    required this.canEdit,
  });

  /// The latest session — the seed on first paint, then whatever the
  /// `watchSession` stream pushes.
  final Session session;

  /// Read-only exercise/superset view models assembled from [session].
  final List<SupersetGroupViewModel> groups;

  /// Whether logged set values may be corrected on this session. Computed once
  /// at open (in-week + ended) and held stable for the screen's lifetime.
  final bool canEdit;

  /// Whether this session was logged as a deload — drives the DELOAD badge on
  /// the review header.
  bool get isDeload => session.isDeload;

  @override
  List<Object?> get props => [session, groups, canEdit];
}
