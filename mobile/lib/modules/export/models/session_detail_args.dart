import 'package:zamaj/modules/domain/domain.dart';

/// Navigation arguments for the read-only session detail screen.
///
/// Carries the already-hydrated [Session] (held by the recent-sessions list)
/// so the detail screen needs no refetch and no bloc. Unlike
/// [RecentSessionsArgs] this is not serialized — the screen is read-only and
/// always reached with a live in-memory session.
final class SessionDetailArgs {
  const SessionDetailArgs({required this.session});

  final Session session;
}
