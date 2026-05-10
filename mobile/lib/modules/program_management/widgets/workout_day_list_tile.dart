import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

class WorkoutDayListTile extends StatelessWidget {
  const WorkoutDayListTile({
    super.key,
    required this.name,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      tileColor: colors.surface,
      title: Text(name, style: TextStyle(color: colors.onSurface)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colors.onSurfaceMuted),
            tooltip: 'Rename',
            onPressed: onRename,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.onSurfaceMuted),
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
          Icon(Icons.drag_handle, color: colors.onSurfaceMuted),
        ],
      ),
      onTap: onTap,
    );
  }
}
