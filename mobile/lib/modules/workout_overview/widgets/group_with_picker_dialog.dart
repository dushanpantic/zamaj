import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

/// Modal picker that lists every unfinished, non-grouped exercise *and*
/// every existing unfinished superset other than the source. Resolves to
/// any one `sessionExerciseId` belonging to the chosen target — the caller
/// feeds it through the same drop-resolved event the drag-onto-card flow
/// uses, and the resolver routes it to either createSuperset or
/// addToSuperset depending on whether the target is grouped.
abstract final class GroupWithPickerDialog {
  /// [candidates] — standalone unfinished, non-grouped exercises.
  /// [supersetGroups] — existing unfinished supersets to allow joining; pass
  /// an empty list if the source can only create new supersets.
  static Future<String?> show({
    required BuildContext context,
    required List<ExerciseViewModel> candidates,
    List<SupersetGroup> supersetGroups = const [],
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).appColors;
        const typography = AppTypography.standard;
        final totalRows = candidates.length + supersetGroups.length;
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
              itemCount: totalRows,
              itemBuilder: (_, i) {
                if (i < supersetGroups.length) {
                  final group = supersetGroups[i];
                  return ListTile(
                    leading: Icon(Icons.link, color: colors.primary),
                    title: Text(
                      'Add to: ${_groupLabel(group)}',
                      style: typography.body.copyWith(color: colors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(
                      ctx,
                    ).pop(group.exercises.first.sessionExercise.id),
                    minVerticalPadding: AppSpacing.sm,
                  );
                }
                final c = candidates[i - supersetGroups.length];
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

  static String _groupLabel(SupersetGroup group) {
    return group.exercises.map(_displayName).join(' + ');
  }
}
