import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_list_tile.dart';

class ProgramEditorDayList extends StatelessWidget {
  const ProgramEditorDayList({
    super.key,
    required this.state,
    required this.workoutDays,
    required this.editingDayDraftId,
    required this.expandedDayDraftIds,
    required this.onAddWorkoutDay,
    required this.onDeletePressed,
    required this.onEnterRename,
    required this.onExitRename,
    required this.onToggleExpand,
  });

  final ProgramEditorEditing state;
  final List<WorkoutDayDraft> workoutDays;
  final String? editingDayDraftId;
  final Set<String> expandedDayDraftIds;
  final VoidCallback onAddWorkoutDay;
  final void Function({
    required String draftId,
    required WorkoutDaySummary summary,
  })
  onDeletePressed;
  final ValueChanged<String> onEnterRename;
  final ValueChanged<String> onExitRename;
  final ValueChanged<String> onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    if (workoutDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: colors.onSurfaceMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No workout days yet',
                style: typography.titleSmall.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Build out your week one day at a time.',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: onAddWorkoutDay,
                icon: const Icon(Icons.add),
                label: const Text('Add workout day'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(0, AppSpacing.touchMin),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(ProgramManagementRoutes.planImport),
                icon: Icon(Icons.content_paste, color: colors.primary),
                label: Text(
                  'Paste a plan',
                  style: typography.label.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom:
            AppSpacing.xxxl +
            AppSpacing.xl +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: workoutDays.length,
      onReorder: (oldIndex, newIndex) {
        final days = List.of(workoutDays);
        if (newIndex > oldIndex) newIndex -= 1;
        final moved = days.removeAt(oldIndex);
        days.insert(newIndex, moved);
        context.read<ProgramEditorBloc>().add(
          ProgramEditorWorkoutDaysReordered(
            orderedDraftIds: days.map((d) => d.draftId).toList(),
          ),
        );
      },
      itemBuilder: (context, index) {
        final day = workoutDays[index];
        final summary = state.summaryFor(day);
        final preview = state.exercisePreviewFor(day);
        final canDuplicate = day.persistedId != null;
        final isExpanded = expandedDayDraftIds.contains(day.draftId);

        return WorkoutDayListTile(
          key: ValueKey(day.draftId),
          index: index,
          name: day.name,
          summary: summary,
          isPersisted: day.persistedId != null,
          onTap: day.persistedId != null
              ? () => Navigator.of(context).pushNamed(
                  ProgramManagementRoutes.workoutDay,
                  arguments: WorkoutDayArgs(workoutDayId: day.persistedId!),
                )
              : null,
          onRename: (newName) {
            context.read<ProgramEditorBloc>().add(
              ProgramEditorWorkoutDayRenamed(
                draftId: day.draftId,
                name: newName,
              ),
            );
          },
          onDuplicate: canDuplicate
              ? () => context.read<ProgramEditorBloc>().add(
                  ProgramEditorWorkoutDayDuplicated(draftId: day.draftId),
                )
              : null,
          onDelete: () =>
              onDeletePressed(draftId: day.draftId, summary: summary),
          isEditing: editingDayDraftId == day.draftId,
          onEnterRename: () => onEnterRename(day.draftId),
          onExitRename: () => onExitRename(day.draftId),
          exercisePreview: preview,
          isExpanded: isExpanded,
          onToggleExpand: preview.isEmpty
              ? null
              : () => onToggleExpand(day.draftId),
        );
      },
    );
  }
}
