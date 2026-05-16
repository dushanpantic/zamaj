import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/focus_mode/models/rest_timer_view_model.dart';

/// Inline rest-timer bar.
///
/// Shows mm:ss elapsed (or remaining when a plan exists), with controls for
/// pause/resume, +15s, and skip. Tints orange normally, red once overtime.
/// Buttons are sized to [AppSpacing.touchMin] so sweaty mid-set fingers don't
/// miss. Persistence and foreground notifications land in spec 7.
class FocusRestTimerBar extends StatelessWidget {
  const FocusRestTimerBar({
    super.key,
    required this.timer,
    required this.onPauseToggle,
    required this.onExtend,
    required this.onSkip,
  });

  final RestTimerViewModel timer;
  final VoidCallback onPauseToggle;
  final VoidCallback onExtend;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isOvertime = timer.isOvertime;
    final tint = isOvertime ? colors.restTimerOvertime : colors.restTimer;
    final remaining = timer.remainingSeconds;
    final showRemaining = remaining != null;
    final displaySeconds = showRemaining
        ? remaining.abs()
        : timer.elapsedSeconds;
    final prefix = showRemaining ? (isOvertime ? '-' : '') : '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: tint.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: tint, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$prefix${_formatMmss(displaySeconds)}',
            style: typography.numericMd.copyWith(color: tint),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            showRemaining ? (isOvertime ? 'over' : 'rest') : 'resting',
            style: typography.caption.copyWith(color: colors.onSurfaceMuted),
          ),
          const Spacer(),
          IconButton(
            tooltip: timer.isPaused ? 'Resume' : 'Pause',
            onPressed: onPauseToggle,
            icon: Icon(timer.isPaused ? Icons.play_arrow : Icons.pause),
            color: colors.onSurface,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchMin,
              minHeight: AppSpacing.touchMin,
            ),
          ),
          TextButton(
            onPressed: onExtend,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, AppSpacing.touchMin),
              foregroundColor: colors.onSurface,
            ),
            child: const Text('+15'),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              minimumSize: const Size(0, AppSpacing.touchMin),
              foregroundColor: colors.onSurfaceMuted,
            ),
            child: const Text('Skip'),
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
