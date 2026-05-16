import 'package:share_plus/share_plus.dart' hide ShareResult;
import 'package:zamaj/modules/export/services/share_service.dart';

/// `share_plus`-backed implementation of [ShareService].
///
/// share_plus 11+ exposes the share entry point through [SharePlus.instance];
/// older `Share.share(...)` static calls are deprecated and removed in v12.
final class SharePlusShareService implements ShareService {
  const SharePlusShareService();

  @override
  Future<ShareResult> shareText(String text, {String? subject}) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      return switch (result.status) {
        ShareResultStatus.success => const ShareCompleted(),
        ShareResultStatus.dismissed => const ShareDismissed(),
        ShareResultStatus.unavailable => const ShareFailed(
          'Sharing is not available on this device',
        ),
      };
    } catch (e) {
      return ShareFailed(e.toString());
    }
  }
}
