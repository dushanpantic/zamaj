import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class WorkoutDayPickerEmptyView extends StatelessWidget {
  const WorkoutDayPickerEmptyView({
    super.key,
    required this.programName,
    required this.onEditProgram,
  });

  final String programName;
  final VoidCallback onEditProgram;

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
            Icon(
              Icons.event_note_outlined,
              color: colors.onSurfaceMuted,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              programName,
              style: typography.title.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This program has no workout days yet.',
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onEditProgram,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit program'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
