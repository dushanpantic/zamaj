import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Tonal intent of an [AppMenuRow]. Drives the icon + label colour the same way
/// [AppNoticeTone] / `AppStateTone` pick their accent. The default [normal]
/// reads at full `onSurface` strength (not muted); [warning] is a reversible
/// caution (e.g. Archive), [destructive] an irreversible action (e.g. Delete),
/// matching `AppConfirmDialog`'s destructive vocabulary.
enum AppMenuRowTone { normal, warning, destructive }

/// The one popup-menu / action-sheet row for the app.
///
/// A small themed row — [AppIconSize.md] glyph, [AppSpacing.md] gap, a
/// `typography.label` — used as the `child` of a `PopupMenuItem`.
///
/// Sizing/height come from the enclosing `PopupMenuItem` (which centres its
/// child in a `kMinInteractiveDimension` tap target), so this widget only owns
/// the icon + label content. Set [enabled] to `false` to mirror a disabled
/// `PopupMenuItem` — the row greys to `onSurfaceMuted`.
class AppMenuRow extends StatelessWidget {
  const AppMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.tone = AppMenuRowTone.normal,
    this.enabled = true,
  });

  /// Leading glyph for the action.
  final IconData icon;

  /// Action label.
  final String label;

  /// Drives the icon + label colour.
  final AppMenuRowTone tone;

  /// When `false`, greys the row to `onSurfaceMuted` to match a disabled
  /// `PopupMenuItem`.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final color = !enabled
        ? colors.onSurfaceMuted
        : switch (tone) {
            AppMenuRowTone.normal => colors.onSurface,
            AppMenuRowTone.warning => colors.warning,
            AppMenuRowTone.destructive => colors.error,
          };

    return Row(
      children: [
        AppIcon(icon, size: AppIconSize.md, color: color),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: typography.label.copyWith(color: color)),
      ],
    );
  }
}
