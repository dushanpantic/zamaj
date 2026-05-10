import 'package:url_launcher/url_launcher.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';

final class UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher {
  const UrlLauncherExternalLinkLauncher();

  static const _youtubeHosts = {
    'youtube.com',
    'youtu.be',
    'm.youtube.com',
    'www.youtube.com',
  };

  @override
  Future<ExternalLinkResult> launch(Uri url) async {
    final mode = _youtubeHosts.contains(url.host)
        ? LaunchMode.externalApplication
        : LaunchMode.platformDefault;

    try {
      final launched = await launchUrl(url, mode: mode);
      if (launched) return const ExternalLinkOpened();
      return const ExternalLinkFailure('url_launcher returned false');
    } catch (e) {
      return ExternalLinkFailure(e.toString());
    }
  }
}
