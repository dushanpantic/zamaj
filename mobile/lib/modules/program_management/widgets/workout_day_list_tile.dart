import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

class WorkoutDayListTile extends StatelessWidget {
  const WorkoutDayListTile({
    super.key,
    required this.name,
    this.onTap,
    required this.onDelete,
  });

  final String name;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Dismissible(
      key: key ?? ValueKey(name),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: colors.error,
        child: Icon(Icons.delete_outline, color: colors.onPrimary),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        tileColor: colors.surface,
        title: Text(name, style: TextStyle(color: colors.onSurface)),
        trailing: Icon(Icons.drag_handle, color: colors.onSurfaceMuted),
        onTap: onTap,
      ),
    );
  }
}
