import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.onTap,
    required this.onDelete,
    this.reorderIndex,
  });

  final ExerciseDraft exercise;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Material(
      color: colors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              if (reorderIndex != null)
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(Icons.drag_handle, size: 20),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name.isEmpty
                          ? 'Unnamed exercise'
                          : exercise.name,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _measurementLabel(exercise),
                      style: TextStyle(
                        color: colors.onSurfaceMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: AppSpacing.touchMin,
                  minHeight: AppSpacing.touchMin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _measurementLabel(ExerciseDraft exercise) {
    return switch (exercise.measurementType) {
      RepBasedMeasurement() => 'Rep-based',
      TimeBasedMeasurement() => 'Time-based',
    };
  }
}
