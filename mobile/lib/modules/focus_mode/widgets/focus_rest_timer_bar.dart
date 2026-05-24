import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/focus_mode/models/rest_timer_view_model.dart';

/// Slim rest-timer bar. A thin progress line shrinks left-to-right as the
/// rest depletes; mm:ss remaining sits on the left, a SKIP affordance on
/// the right. The bloc auto-dismisses the timer when it reaches zero, so
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(_barHeight / 2),
            child: SizedBox(
              height: _barHeight,
              child: LinearProgressIndicator(
                value: timer.remainingFraction,
                backgroundColor: tint.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(tint),
                minHeight: _barHeight,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                _formatMmss(timer.remainingSeconds),
                style: typography.caption.copyWith(color: tint),
              ),
              const Spacer(),
              InkWell(
                onTap: onSkip,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSpacing.touchMin,
                    minWidth: AppSpacing.touchMin,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Center(
                      child: Text(
                        'SKIP',
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
