import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';

enum WorkoutDayMenuAction { rename, duplicate, delete }

class WorkoutDayListTile extends StatefulWidget {
  const WorkoutDayListTile({
    super.key,
    required this.index,
    required this.name,
    required this.summary,
    required this.isPersisted,
    this.onTap,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.isEditing,
    required this.onEnterRename,
    required this.onExitRename,
    this.exercisePreview = const [],
    this.isExpanded = false,
    this.onToggleExpand,
  });

  final int index;
  final String name;
  final WorkoutDaySummary summary;
  final bool isPersisted;
  final VoidCallback? onTap;
  final ValueChanged<String> onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback onDelete;

  /// True when this tile should render its inline rename text field.
  final bool isEditing;
  final VoidCallback onEnterRename;
  final VoidCallback onExitRename;

  /// Ordered list of exercise names shown in the inline-expand peek. Caller
  /// is responsible for trimming to the desired preview length.
  final List<String> exercisePreview;

  /// When true the tile renders the [exercisePreview] panel below its
  /// header row.
  final bool isExpanded;

  /// Toggle for the expand/collapse chevron. `null` hides the chevron
  /// (e.g. when the day is not persisted yet or has no exercises to peek).
  final VoidCallback? onToggleExpand;

  @override
  State<WorkoutDayListTile> createState() => _WorkoutDayListTileState();
}

class _WorkoutDayListTileState extends State<WorkoutDayListTile> {
  late final TextEditingController _renameController;
  late final FocusNode _renameFocus;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.name);
    _renameFocus = FocusNode();
    if (widget.isEditing) _activateEditing();
  }

  @override
  void didUpdateWidget(covariant WorkoutDayListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name && !widget.isEditing) {
      _renameController.text = widget.name;
    }
    if (widget.isEditing && !oldWidget.isEditing) {
      _renameController.value = TextEditingValue(
        text: widget.name,
        selection: TextSelection.collapsed(offset: widget.name.length),
      );
      _activateEditing();
    }
  }

  void _activateEditing() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _renameFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _renameController.dispose();
    _renameFocus.dispose();
    super.dispose();
  }

  void _commitRename() {
    final trimmed = _renameController.text.trim();
    if (trimmed.isNotEmpty && trimmed != widget.name) {
      widget.onRename(trimmed);
    } else {
      // Reset to current name if empty / unchanged.
      _renameController.text = widget.name;
    }
    widget.onExitRename();
  }

  void _cancelRename() {
    _renameController.text = widget.name;
    widget.onExitRename();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isEmpty = widget.summary.isEmpty;
    final subtitleColor = isEmpty ? colors.error : colors.onSurfaceMuted;
    final tapHandler = widget.isEditing ? null : widget.onTap;
    final canExpand =
        widget.onToggleExpand != null && widget.exercisePreview.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: tapHandler,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchMin + AppSpacing.sm * 2,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _DragHandle(index: widget.index),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: widget.isEditing
                                    ? _RenameField(
                                        controller: _renameController,
                                        focusNode: _renameFocus,
                                        onSubmit: _commitRename,
                                        onCancel: _cancelRename,
                                      )
                                    : Text(
                                        widget.name,
                                        style: typography.titleSmall.copyWith(
                                          color: colors.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                              if (isEmpty && !widget.isEditing) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const _EmptyBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            WorkoutDaySummaryFormatter.format(widget.summary),
                            style: typography.caption.copyWith(
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (canExpand && !widget.isEditing)
                      _ExpandToggle(
                        isExpanded: widget.isExpanded,
                        onPressed: widget.onToggleExpand!,
                      ),
                    if (widget.isEditing)
                      _RenameActions(
                        onCommit: _commitRename,
                        onCancel: _cancelRename,
                      )
                    else
                      _DayMenu(
                        isPersisted: widget.isPersisted,
                        canDuplicate: widget.onDuplicate != null,
                        onSelected: (action) {
                          switch (action) {
                            case WorkoutDayMenuAction.rename:
                              widget.onEnterRename();
                            case WorkoutDayMenuAction.duplicate:
                              widget.onDuplicate?.call();
                            case WorkoutDayMenuAction.delete:
                              widget.onDelete();
                          }
                        },
                      ),
                  ],
                ),
                if (widget.isExpanded && widget.exercisePreview.isNotEmpty)
                  _ExercisePreviewPanel(
                    exerciseNames: widget.exercisePreview,
                    totalExerciseCount:
                        widget.summary.exerciseCount +
                        widget.summary.warmupExerciseCount,
                    onEditDay: widget.onTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({required this.isExpanded, required this.onPressed});

  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return IconButton(
      icon: AnimatedRotation(
        turns: isExpanded ? 0.25 : 0,
        duration: AppDuration.base,
        child: Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
      ),
      onPressed: onPressed,
      tooltip: isExpanded ? 'Hide exercises' : 'Peek exercises',
    );
  }
}

class _ExercisePreviewPanel extends StatelessWidget {
  const _ExercisePreviewPanel({
    required this.exerciseNames,
    required this.totalExerciseCount,
    required this.onEditDay,
  });

  final List<String> exerciseNames;
  final int totalExerciseCount;
  final VoidCallback? onEditDay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final remaining = totalExerciseCount - exerciseNames.length;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xxl + AppSpacing.xs,
        right: AppSpacing.sm,
        top: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final name in exerciseNames)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.onSurfaceMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '+ $remaining more',
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
          if (onEditDay != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEditDay,
                icon: AppIcon(
                  Icons.edit,
                  size: AppIconSize.sm,
                  color: colors.primary,
                ),
                label: Text(
                  'Edit day',
                  style: typography.label.copyWith(color: colors.primary),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: 'Drag to reorder',
        child: SizedBox(
          width: AppSpacing.xxl,
          height: AppSpacing.touchMin,
          child: AppIcon(
            Icons.drag_indicator,
            size: AppIconSize.lg,
            color: colors.onSurfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _EmptyBadge extends StatelessWidget {
  const _EmptyBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.error.withValues(alpha: 0.5)),
      ),
      child: Text(
        'EMPTY',
        style: AppTypography.standard.badge.copyWith(color: colors.error),
      ),
    );
  }
}

class _DayMenu extends StatelessWidget {
  const _DayMenu({
    required this.isPersisted,
    required this.canDuplicate,
    required this.onSelected,
  });

  final bool isPersisted;
  final bool canDuplicate;
  final ValueChanged<WorkoutDayMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return PopupMenuButton<WorkoutDayMenuAction>(
      icon: Icon(Icons.more_vert, color: colors.onSurfaceMuted),
      tooltip: 'Workout day actions',
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outline),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: WorkoutDayMenuAction.rename,
          enabled: isPersisted,
          child: _MenuRow(
            icon: Icons.edit,
            label: 'Rename',
            color: colors.onSurface,
            disabled: !isPersisted,
            typography: typography,
          ),
        ),
        PopupMenuItem(
          value: WorkoutDayMenuAction.duplicate,
          enabled: canDuplicate,
          child: _MenuRow(
            icon: Icons.copy,
            label: 'Duplicate',
            color: colors.onSurface,
            disabled: !canDuplicate,
            typography: typography,
          ),
        ),
        PopupMenuItem(
          value: WorkoutDayMenuAction.delete,
          child: _MenuRow(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: colors.error,
            disabled: false,
            typography: typography,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.disabled,
    required this.typography,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool disabled;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final effective = disabled ? colors.onSurfaceMuted : color;
    return Row(
      children: [
        AppIcon(icon, size: AppIconSize.md, color: effective),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: typography.label.copyWith(color: effective)),
      ],
    );
  }
}

class _RenameField extends StatelessWidget {
  const _RenameField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      style: typography.titleSmall.copyWith(color: colors.onSurface),
      maxLength: 100,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.primary),
        ),
        hintText: 'Day name',
        hintStyle: typography.titleSmall.copyWith(color: colors.onSurfaceMuted),
      ),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
    );
  }
}

class _RenameActions extends StatelessWidget {
  const _RenameActions({required this.onCommit, required this.onCancel});

  final VoidCallback onCommit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onCancel,
          icon: Icon(Icons.close, color: colors.onSurfaceMuted),
          tooltip: 'Cancel rename',
        ),
        IconButton(
          onPressed: onCommit,
          icon: Icon(Icons.check, color: colors.primary),
          tooltip: 'Save name',
        ),
      ],
    );
  }
}
