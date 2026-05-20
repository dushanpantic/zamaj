import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/relative_date_formatter.dart';
import 'package:zamaj/modules/export/models/session_history_item.dart';

class SessionHistoryTile extends StatelessWidget {
  const SessionHistoryTile({
    super.key,
    required this.item,
    required this.referenceNow,
    required this.onPressed,
    this.onDelete,
  });

  final SessionHistoryItem item;
  final DateTime referenceNow;
  final VoidCallback onPressed;

  /// When non-null, a kebab menu appears in the trailing slot with a
  /// "Delete" action that invokes this callback. The screen is responsible
  /// for any confirmation flow.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final relative = item.endedAt == null
        ? '—'
        : RelativeDateFormatter.format(item.endedAt!, referenceNow);
    final progress = item.totalExerciseCount == 0
        ? 'No exercises'
        : '${item.completedExerciseCount}/${item.totalExerciseCount} exercises';

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.outline),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.md),
                ),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.workoutDayName,
                        style: typography.titleSmall.copyWith(
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$relative · $progress',
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onDelete != null)
              _TileMenuButton(onDelete: onDelete!)
            else
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Icon(
                  Icons.ios_share,
                  size: 20,
                  color: colors.onSurfaceMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TileMenuButton extends StatelessWidget {
  const _TileMenuButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return PopupMenuButton<_TileMenuAction>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert, color: colors.onSurfaceMuted),
      onSelected: (action) {
        switch (action) {
          case _TileMenuAction.delete:
            onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _TileMenuAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: colors.error),
              const SizedBox(width: AppSpacing.md),
              Text('Delete', style: TextStyle(color: colors.error)),
            ],
          ),
        ),
      ],
    );
  }
}

enum _TileMenuAction { delete }
