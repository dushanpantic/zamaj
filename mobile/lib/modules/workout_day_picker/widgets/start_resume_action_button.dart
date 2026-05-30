import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

/// Primary action on the Day Picker tile. Filled visual treatment because
/// "start a workout" is the screen's top user goal; Resume gets the same
/// emphasis since interrupted sessions are the most-recoverable state.
class StartResumeActionButton extends StatelessWidget {
  const StartResumeActionButton({
    super.key,
    required this.isResume,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final bool isResume;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final label = isResume ? 'RESUME' : 'START';
    final canTap = enabled && !busy;

    return SizedBox(
      height: AppSpacing.touchMin,
      child: FilledButton.icon(
        onPressed: canTap ? onPressed : null,
        icon: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : AppIcon(
                isResume ? Icons.play_arrow : Icons.fitness_center,
                size: AppIconSize.lg,
              ),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceVariant,
          disabledForegroundColor: colors.onSurfaceMuted,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        ),
      ),
    );
  }
}
