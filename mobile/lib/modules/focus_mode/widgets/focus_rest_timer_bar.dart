import 'package:flutter/material.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/focus_mode/models/rest_timer_view_model.dart';

/// Compact rest-timer strip, all on one row: a small mm:ss readout, a thin
/// progress line that depletes left-to-right between them, and a small SKIP on
/// the right. Remaining time is read primarily off the bar, so the readout and
/// SKIP are intentionally minimal — a deliberate exception to the in-session
/// 56 dp sizing (see CLAUDE.md). The bloc auto-dismisses the timer at zero, so
/// there is no overtime state to render.
class FocusRestTimerBar extends StatelessWidget {
  const FocusRestTimerBar({
    super.key,
    required this.timer,
    required this.onSkip,
  });

  final RestTimerViewModel timer;
  final VoidCallback onSkip;

  static const double _barHeight = 3;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final tint = colors.restTimer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Small tabular glance; the bar is the primary remaining-time signal.
          Text(
            _formatMmss(timer.remainingSeconds),
            style: typography.numericXs.copyWith(color: tint),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_barHeight / 2),
              child: SizedBox(
                height: _barHeight,
                child: LinearProgressIndicator(
                  value: timer.remainingFraction,
                  backgroundColor: tint.withValues(alpha: AppOpacity.recede1),
                  valueColor: AlwaysStoppedAnimation<Color>(tint),
                  minHeight: _barHeight,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Deliberate exception to the in-session 56 dp floor: time is read
          // off the bar and SKIP is rarely tapped, so keep it as small as
          // possible while staying tappable at arm's length.
          InkWell(
            onTap: onSkip,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                'SKIP',
                style: typography.labelSmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMmss(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}
