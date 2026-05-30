import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_typography.dart';

/// The one status marker for the app, encoding the single Phase 0.2
/// vocabulary so "how we show state" stops reading like three authors:
///
/// * [StatusBadge.icon] — a tooltipped glyph for positive / neutral states
///   (done check, warmup flame). Quiet by design, and never colour-only: the
///   tooltip + semantic label always name the state.
/// * [StatusBadge.pill] — a rounded, tinted pill for exception / high-stakes
///   states (the sanctioned in-progress exception, plus Skipped / Replaced).
///   The caller supplies the casing — in-progress stays UPPERCASE, while
///   Skipped / Replaced are Title-case — and the colour, from which the fill
///   and hairline border are derived.
///
/// Both branches read their dimensions from tokens ([AppIconSize.status],
/// [AppStroke.hairline], the [AppTypography.badge] style), so a new status
/// inherits the right size rather than re-deriving it.
class StatusBadge extends StatelessWidget {
  /// Glyph variant for positive / neutral states. [label] is used as both the
  /// tooltip message and the screen-reader label so the state is announced.
  const StatusBadge.icon({
    super.key,
    required IconData icon,
    required Color color,
    required String label,
  }) : _icon = icon,
       _color = color,
       _label = label,
       _isPill = false;

  /// Pill variant for exception / high-stakes states.
  const StatusBadge.pill({
    super.key,
    required String label,
    required Color color,
  }) : _icon = null,
       _color = color,
       _label = label,
       _isPill = true;

  final IconData? _icon;
  final Color _color;
  final String _label;
  final bool _isPill;

  @override
  Widget build(BuildContext context) {
    if (!_isPill) {
      return Tooltip(
        message: _label,
        child: AppIcon(
          _icon!,
          size: AppIconSize.status,
          color: _color,
          semanticLabel: _label,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: _color.withValues(alpha: AppOpacity.borderTint),
          width: AppStroke.hairline,
        ),
      ),
      child: Text(
        _label,
        style: AppTypography.standard.badge.copyWith(color: _color),
      ),
    );
  }
}
