abstract interface class ExternalLinkLauncher {
  Future<ExternalLinkResult> launch(Uri url);
}

sealed class ExternalLinkResult {
  const ExternalLinkResult();
}

final class ExternalLinkOpened extends ExternalLinkResult {
  const ExternalLinkOpened();
}

final class ExternalLinkFailure extends ExternalLinkResult {
  const ExternalLinkFailure(this.reason);
  final String reason;
}
