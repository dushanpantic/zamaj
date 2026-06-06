import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/relative_date_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

class ProgramListTile extends StatelessWidget {
  const ProgramListTile({
    super.key,
    required this.program,
    required this.onTap,
    required this.onEdit,
    required this.onDeleteRequested,
    this.isInProgress = false,
    this.isDeleting = false,
  });

  final Program program;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDeleteRequested;

  /// Whether the in-flight session belongs to this program. Drives the
  /// "In progress" label next to the title and the left-edge accent bar.
  final bool isInProgress;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final isEmpty = program.workoutDayIds.isEmpty;
    final dayCount = program.workoutDayIds.length;
    final dayCountLabel = dayCount == 1 ? '1 day' : '$dayCount days';
    final relativeDate = _formatDate(program.updatedAt);

    final captionStyle = typography.caption.copyWith(
      color: colors.onSurfaceMuted,
    );

    final body = Container(
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
            child: Semantics(
              label: _semanticsLabel(dayCountLabel, relativeDate, isEmpty),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          program.name,
                          style: typography.title.copyWith(
                            color: colors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isInProgress) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const InProgressLabel(),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _metadata(
                    captionStyle: captionStyle,
                    isEmpty: isEmpty,
                    dayCountLabel: dayCountLabel,
                    relativeDate: relativeDate,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (isDeleting)
            SizedBox(
              width: AppSpacing.xl,
              height: AppSpacing.xl,
              child: CircularProgressIndicator(
                strokeWidth: AppStroke.indicator,
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
                    onEdit();
                  case _TileAction.delete:
                    onDeleteRequested();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _TileAction.edit,
                  child: AppMenuRow(icon: Icons.edit_outlined, label: 'Edit'),
                ),
                const PopupMenuItem(
                  value: _TileAction.delete,
                  child: AppMenuRow(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    tone: AppMenuRowTone.destructive,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    final content = isInProgress
        ? Stack(children: [body, const InProgressAccentBar()])
        : body;

    final tile = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
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

  /// Metadata line: `"{days}, edited {date}"`, or `"No days yet. Tap to set
  /// up."` for a draft. The in-progress signal lives in the title badge and the
  /// accent bar, not here.
  Widget _metadata({
    required TextStyle captionStyle,
    required bool isEmpty,
    required String dayCountLabel,
    required String relativeDate,
  }) {
    if (isEmpty) {
      return Text('No days yet. Tap to set up.', style: captionStyle);
    }
    return Text('$dayCountLabel, edited $relativeDate', style: captionStyle);
  }

  String _semanticsLabel(
    String dayCountLabel,
    String relativeDate,
    bool isEmpty,
  ) {
    if (isEmpty) {
      return '${program.name}, draft, no days yet, tap to set up';
    }
    final state = isInProgress ? 'in progress, ' : '';
    return '${program.name}, $state$dayCountLabel, edited $relativeDate';
  }

  String _formatDate(DateTime date) =>
      RelativeDateFormatter.format(date, DateTime.now());
}

enum _TileAction { edit, delete }
