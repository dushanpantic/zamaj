import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// The single confirm-dialog path for the app: a title, a body, and a
/// cancel / confirm pair. Background, border, radius, and text styles come
/// from `dialogTheme` (see [AppTheme]) so every confirmation looks identical;
/// only the destructive accent on the confirm action is decided here.
///
/// Use [AppConfirmDialog.show] rather than constructing it directly:
///
/// ```dart
/// final confirmed = await AppConfirmDialog.show(
///   context: context,
///   title: 'Delete program?',
///   body: 'Removes it from the picker, kept in your history.',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// ```
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDestructive = false,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  /// Shows the dialog and resolves to `true` on confirm, `false` on cancel,
  /// and `null` if dismissed by tapping the scrim.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String body,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AppConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: typography.label.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: typography.label.copyWith(
              color: isDestructive ? colors.error : colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
