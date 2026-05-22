import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/widgets/measurement_type_chip.dart';

class LibraryEntryTile extends StatelessWidget {
  const LibraryEntryTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onArchive,
    required this.onUnarchive,
    this.isMutating = false,
  });

  final LibraryExercise entry;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onUnarchive;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isArchived = entry.archivedAt != null;

    return Opacity(
      opacity: isArchived ? 0.6 : 1.0,
      child: InkWell(
        onTap: isMutating ? null : onTap,
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
                      entry.name,
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        MeasurementTypeChip(
                          measurementType: entry.measurementType,
                        ),
                        if (isArchived) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Archived',
                            style: typography.caption.copyWith(
                              color: colors.onSurfaceMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isMutating)
                SizedBox(
                  width: AppSpacing.xl,
                  height: AppSpacing.xl,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              else
                PopupMenuButton<_TileAction>(
                  tooltip: 'More actions',
                  icon: Icon(Icons.more_vert, color: colors.onSurfaceMuted),
                  onSelected: (action) {
                    switch (action) {
                      case _TileAction.edit:
                        onTap();
                      case _TileAction.archive:
                        onArchive();
                      case _TileAction.unarchive:
                        onUnarchive();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _TileAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    if (isArchived)
                      const PopupMenuItem(
                        value: _TileAction.unarchive,
                        child: ListTile(
                          leading: Icon(Icons.unarchive_outlined),
                          title: Text('Restore'),
                        ),
                      )
                    else
                      PopupMenuItem(
                        value: _TileAction.archive,
                        child: ListTile(
                          leading: Icon(
                            Icons.archive_outlined,
                            color: colors.warning,
                          ),
                          title: Text(
                            'Archive',
                            style: TextStyle(color: colors.warning),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TileAction { edit, archive, unarchive }
