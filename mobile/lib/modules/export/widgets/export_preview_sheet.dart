import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/export/services/share_service.dart';

/// Modal bottom sheet that displays a formatted export and lets the user
/// copy it to the clipboard or invoke the OS share sheet.
///
/// Reads its [ShareService] from the surrounding [BlocProvider] /
/// [RepositoryProvider] tree (wired in `app.dart`).
class ExportPreviewSheet extends StatefulWidget {
  const ExportPreviewSheet({
    super.key,
    required this.title,
    required this.text,
    this.shareSubject,
  });

  final String title;
  final String text;
  final String? shareSubject;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String text,
    String? shareSubject,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appColors.surface,
      builder: (_) => RepositoryProvider<ShareService>.value(
        value: context.read<ShareService>(),
        child: ExportPreviewSheet(
          title: title,
          text: text,
          shareSubject: shareSubject,
        ),
      ),
    );
  }

  @override
  State<ExportPreviewSheet> createState() => _ExportPreviewSheetState();
}

class _ExportPreviewSheetState extends State<ExportPreviewSheet> {
  bool _shareInFlight = false;

  Future<void> _onCopy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _onShare() async {
    if (_shareInFlight) return;
    setState(() => _shareInFlight = true);
    final result = await context.read<ShareService>().shareText(
      widget.text,
      subject: widget.shareSubject,
    );
    if (!mounted) return;
    setState(() => _shareInFlight = false);
    if (result is ShareFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share: ${result.reason}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: typography.title.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.outline),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.text,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                      fontFamily: 'monospace',
                      fontFamilyFallback: const ['Menlo', 'Courier'],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onCopy,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _shareInFlight ? null : _onShare,
                    icon: _shareInFlight
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
