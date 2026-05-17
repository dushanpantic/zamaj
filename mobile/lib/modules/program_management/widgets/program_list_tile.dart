import 'package:flutter/material.dart';
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
    this.isDeleting = false,
  });

  final Program program;
  final VoidCallback onTap;
  final VoidCallback onEdit;
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
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _TileAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: colors.error),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  ),
                ],
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

  String _formatDate(DateTime date) =>
      RelativeDateFormatter.format(date, DateTime.now());
}

enum _TileAction { edit, delete }
