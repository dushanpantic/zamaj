import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

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
      child: OutlinedButton(
        onPressed: canTap ? onPressed : null,
        child: busy
            ? SizedBox(
                width: AppSpacing.lg,
                height: AppSpacing.lg,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
