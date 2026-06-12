import 'package:zamaj/modules/domain/models/session.dart';

/// Selects the single "active" session among a set of sessions.
///
/// A session is a candidate only while it is in progress (no `endedAt`).
/// Among candidates the most recently worked-on wins, ordered by
/// `updatedAt` desc, then `startedAt` desc, then `id` desc. The `id`
/// tie-break makes the choice deterministic.
///
/// This is the single source of truth for "which session is active",
/// shared by the history summarizer and the session repository's
/// `getActiveSession`/`watchActiveSession` ordering.
abstract final class ActiveSessionPolicy {
  /// Returns the active session, or `null` when no session is in progress.
  static Session? select(List<Session> sessions) {
    Session? best;
    for (final s in sessions) {
      if (s.endedAt != null) continue;
      if (best == null || _beats(s, best)) best = s;
    }
    return best;
  }

  static bool _beats(Session candidate, Session current) {
    final byUpdated = candidate.updatedAt.compareTo(current.updatedAt);
    if (byUpdated != 0) return byUpdated > 0;
    final byStarted = candidate.startedAt.compareTo(current.startedAt);
    if (byStarted != 0) return byStarted > 0;
    return candidate.id.compareTo(current.id) > 0;
  }
}
