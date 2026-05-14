import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// End-of-workout panel shown when the cursor has exhausted all
/// actionable exercises. The user can pop back to the overview screen to
/// review and end the session there.
class FocusWorkoutCompleteView extends StatelessWidget {
  const FocusWorkoutCompleteView({
    super.key,
    required this.workoutDayName,
    required this.onBackToOverview,
  });

  final String workoutDayName;
  final VoidCallback onBackToOverview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: colors.exerciseCompleted, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Workout complete',
              style: typography.title.copyWith(color: colors.onBackground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              workoutDayName,
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onBackToOverview,
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('Back to overview'),
            ),
          ],
        ),
      ),
    );
  }
}
