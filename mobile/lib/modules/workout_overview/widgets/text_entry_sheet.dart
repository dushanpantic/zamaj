import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Generic single-text-field bottom sheet used for session notes and extra
/// work on the live-session surface.
///
/// Modeled on [SetValueEditorSheet] (scroll-controlled modal, drag handle,
/// keyboard-aware bottom inset) but with the live-session commit floor: the
/// commit button is [AppInSessionSize.controlMin] (56 dp), deliberately **not**
/// that sheet's calm 48 dp review-surface floor. The field autofocuses so input
/// — and screen-reader focus — lands inside the sheet on open. Returns the
/// trimmed text on commit, or `null` when dismissed without committing.
class TextEntrySheet extends StatefulWidget {
  const TextEntrySheet({
    super.key,
    required this.title,
    required this.hint,
    required this.confirmLabel,
    this.initialValue = '',
    this.maxLines = 4,
    this.maxLength,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String initialValue;
  final int maxLines;
  final int? maxLength;

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String hint,
    required String confirmLabel,
    String initialValue = '',
    int maxLines = 4,
    int? maxLength,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appColors.surfaceElevated,
      builder: (_) => TextEntrySheet(
        title: title,
        hint: hint,
        confirmLabel: confirmLabel,
        initialValue: initialValue,
        maxLines: maxLines,
        maxLength: maxLength,
      ),
    );
  }

  @override
  State<TextEntrySheet> createState() => _TextEntrySheetState();
}

class _TextEntrySheetState extends State<TextEntrySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final canSubmit = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: widget.maxLines,
            minLines: 2,
            maxLength: widget.maxLength,
            decoration: InputDecoration(hintText: widget.hint),
            style: typography.body.copyWith(color: colors.onSurface),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: AppInSessionSize.controlMin,
            child: FilledButton(
              onPressed: canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(widget.confirmLabel, style: typography.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
