import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/export/services/share_service.dart';

/// Modal bottom sheet that displays a formatted export and lets the user
/// copy it to the clipboard or invoke the OS share sheet.
///
/// The body is rebuilt from [buildText] whenever the "Include warmups"
/// toggle flips, so the formatter — not the sheet — owns the rendering.
///
/// Reads its [ShareService] from the surrounding [BlocProvider] /
/// [RepositoryProvider] tree (wired in `app.dart`).
class ExportPreviewSheet extends StatefulWidget {
  const ExportPreviewSheet({
    super.key,
    required this.title,
    required this.buildText,
    this.shareSubject,
    this.initialIncludeWarmups = false,
  });

  final String title;
  final String Function(bool includeWarmups) buildText;
  final String? shareSubject;
  final bool initialIncludeWarmups;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String Function(bool includeWarmups) buildText,
    String? shareSubject,
    bool initialIncludeWarmups = false,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appColors.surfaceElevated,
      builder: (_) => RepositoryProvider<ShareService>.value(
        value: context.read<ShareService>(),
        child: ExportPreviewSheet(
          title: title,
          buildText: buildText,
          shareSubject: shareSubject,
          initialIncludeWarmups: initialIncludeWarmups,
        ),
      ),
    );
  }

  @override
  State<ExportPreviewSheet> createState() => _ExportPreviewSheetState();
}

class _ExportPreviewSheetState extends State<ExportPreviewSheet> {
  bool _shareInFlight = false;
  late bool _includeWarmups = widget.initialIncludeWarmups;
  late String _text = widget.buildText(_includeWarmups);

  void _onIncludeWarmupsChanged(bool value) {
    setState(() {
      _includeWarmups = value;
      _text = widget.buildText(value);
    });
  }

  Future<void> _onCopy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  Future<void> _onShare() async {
    if (_shareInFlight) return;
    setState(() => _shareInFlight = true);
    final result = await context.read<ShareService>().shareText(
      _text,
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
    // `useSafeArea: true` only guards the top, so the sheet still extends behind
    // the Android system navigation bar. Pad the bottom by that inset so the
    // Copy / Share buttons clear the nav buttons (and the gesture bar).
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: typography.title.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Include warmups',
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                Switch(
                  value: _includeWarmups,
                  onChanged: _onIncludeWarmupsChanged,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
                    _text,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                      fontFamily: AppTypography.monoFamily,
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
                    icon: const AppIcon(Icons.copy, size: AppIconSize.md),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _shareInFlight ? null : _onShare,
                    icon: _shareInFlight
                        ? AppInlineSpinner(color: colors.onPrimary)
                        : const AppIcon(Icons.share, size: AppIconSize.md),
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
