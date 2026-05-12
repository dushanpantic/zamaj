import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/models/workout_day_picker_args.dart';
import 'package:zamaj/modules/workout_day_picker/navigation/workout_day_picker_routes.dart';

class ProgramListTile extends StatelessWidget {
  const ProgramListTile({
    super.key,
    required this.program,
    required this.onTap,
    required this.onDeleteRequested,
    this.isDeleting = false,
  });

  final Program program;
  final VoidCallback onTap;
  final VoidCallback onDeleteRequested;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final tile = InkWell(
      onTap: isDeleting ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.name,
                    style: typography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(program.updatedAt),
                    style: typography.caption.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isDeleting)
              SizedBox(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.primary,
                ),
              )
            else
              IconButton(
                onPressed: () => Navigator.of(context).pushNamed(
                  WorkoutDayPickerRoutes.picker,
                  arguments: WorkoutDayPickerArgs(programId: program.id),
                ),
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: colors.primary,
                ),
                tooltip: 'Train',
              ),
          ],
        ),
      ),
    );

    if (isDeleting) return tile;

    return Dismissible(
      key: ValueKey(program.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDeleteRequested();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(Icons.delete_outline, color: colors.onPrimary),
      ),
      child: tile,
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
