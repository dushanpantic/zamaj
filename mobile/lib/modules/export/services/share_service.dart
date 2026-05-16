/// Abstract over the platform share-sheet so the export UI can be tested
/// without invoking real plugins. The concrete `SharePlusShareService`
/// implementation is wired in `bootstrap`.
abstract interface class ShareService {
  /// Invoke the OS share sheet with [text]. [subject] is used as the
  /// suggested subject on platforms that support it (e.g. email apps on
  /// Android). Returns when the share sheet has been dismissed (whether
  /// or not the user actually shared).
  Future<ShareResult> shareText(String text, {String? subject});
}

sealed class ShareResult {
  const ShareResult();
}

final class ShareDismissed extends ShareResult {
  const ShareDismissed();
}

final class ShareCompleted extends ShareResult {
  const ShareCompleted();
}

final class ShareFailed extends ShareResult {
  const ShareFailed(this.reason);
  final String reason;
}
