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

  /// Whether the in-flight session belongs to this program. Drives the accent
  /// bar, the `IN PROGRESS` chip, and the tinted leading anchor.
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
                  Text(
                    program.name,
                    style: typography.titleSmall.copyWith(
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _metadata(
                    captionStyle: captionStyle,
                    primary: colors.primary,
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
        ? Stack(
            children: [
              body,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: AppSpacing.xs,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.md),
                        bottomLeft: Radius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
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

  /// Metadata line: `"{days} · Edited {date}"`, or `"No days yet · Tap to set
  /// up"` for a draft. When the program owns the active session, a quiet
  /// `primary`-coloured `"In progress"` leads the line (the accent bar carries
  /// the louder signal).
  Widget _metadata({
    required TextStyle captionStyle,
    required Color primary,
    required bool isEmpty,
    required String dayCountLabel,
    required String relativeDate,
  }) {
    if (isEmpty) {
      return Text('No days yet · Tap to set up', style: captionStyle);
    }
    final rest = '$dayCountLabel · Edited $relativeDate';
    if (!isInProgress) {
      return Text(rest, style: captionStyle);
    }
    return Text.rich(
      TextSpan(
        style: captionStyle,
        children: [
          TextSpan(
            text: 'In progress',
            style: captionStyle.copyWith(
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' · $rest'),
        ],
      ),
    );
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
