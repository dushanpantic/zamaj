import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';

/// Modal picker that lists every unfinished, non-grouped exercise other
/// than the source. Resolves to the picked exercise's `sessionExerciseId`,
/// which the caller feeds back through the same drop-resolved event the
/// drag-onto-card flow uses — so the bloc logic stays one code path.
abstract final class GroupWithPickerDialog {
  static Future<String?> show({
    required BuildContext context,
    required List<ExerciseViewModel> candidates,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).appColors;
        const typography = AppTypography.standard;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Group with…',
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: candidates.length,
              itemBuilder: (_, i) {
                final c = candidates[i];
                return ListTile(
                  leading: Icon(Icons.link, color: colors.primary),
                  title: Text(
                    _displayName(c),
                    style: typography.body.copyWith(color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.of(ctx).pop(c.sessionExercise.id),
                  minVerticalPadding: AppSpacing.sm,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: typography.label.copyWith(color: colors.onSurfaceMuted),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _displayName(ExerciseViewModel vm) {
    final state = vm.sessionExercise.state;
    return switch (state) {
      ReplacedState(:final substitute) => substitute.name,
      _ => vm.plannedExerciseName,
    };
  }
}
