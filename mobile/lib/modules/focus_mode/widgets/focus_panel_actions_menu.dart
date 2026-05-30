import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_video_button.dart';
import 'package:zamaj/modules/workout_overview/widgets/replace_exercise_dialog.dart';

class FocusPanelActionsMenu extends StatelessWidget {
  const FocusPanelActionsMenu({
    super.key,
    required this.state,
    required this.panel,
    this.showVideoItem = true,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;

  /// Whether the overflow lists "Open video". Suppressed on the active card,
  /// which surfaces a dedicated [FocusVideoButton] in its header instead.
  final bool showVideoItem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final videoUrl = panel.displayMetadata?.videoUrl;
    final hasVideo = showVideoItem && videoUrl != null && videoUrl.isNotEmpty;
    final canMarkDone =
        panel.completedSetsCount > 0 && panel.isLoggable && !panel.isReplaced;
    return PopupMenuButton<_PanelMenuAction>(
      icon: Icon(Icons.more_vert, color: colors.onSurface),
      onSelected: (action) {
        switch (action) {
          case _PanelMenuAction.replace:
            _handleReplace(context);
          case _PanelMenuAction.skip:
            _handleSkip(context);
          case _PanelMenuAction.markDone:
            _handleMarkDone(context);
          case _PanelMenuAction.openVideo:
            if (hasVideo) openExerciseVideo(context, videoUrl);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PanelMenuAction.replace,
          child: ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Replace exercise'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (canMarkDone)
          const PopupMenuItem(
            value: _PanelMenuAction.markDone,
            child: ListTile(
              leading: Icon(Icons.task_alt),
              title: Text('Mark done'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: _PanelMenuAction.skip,
          child: ListTile(
            leading: Icon(Icons.skip_next),
            title: Text('Skip exercise'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (hasVideo)
          const PopupMenuItem(
            value: _PanelMenuAction.openVideo,
            child: ListTile(
              leading: Icon(Icons.play_circle_outline),
              title: Text('Open video'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    );
  }

  Future<void> _handleReplace(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final defaults = resolveReplaceExerciseDefaults(
      sessionExerciseId: panel.sessionExerciseId,
      session: state.sessionState.session,
    );
    if (defaults == null) return;
    final result = await presentReplaceFlow(
      context: context,
      plannedExerciseName: panel.plannedExerciseName,
      defaultMeasurementType: panel.effectiveMeasurementType,
      defaultPlannedValues: defaults.plannedValues,
      defaultSetCount: defaults.setCount,
    );
    if (result == null) return;
    bloc.add(
      FocusModeExerciseReplaced(
        sessionExerciseId: panel.sessionExerciseId,
        substituteName: result.name,
        substituteMeasurementType: result.measurementType,
        substitutePlannedValues: result.plannedValues,
        substituteSetCount: result.setCount,
        substituteMetadata: result.metadata,
        substituteLibraryExerciseId: result.libraryExerciseId,
      ),
    );
  }

  Future<void> _handleSkip(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Skip exercise?',
      body:
          'Marks "${panel.displayExerciseName}" not done and moves on. '
          'This session only.',
      confirmLabel: 'Skip',
      isDestructive: true,
    );
    if (confirmed != true) return;
    bloc.add(FocusModeExerciseSkipped(panel.sessionExerciseId));
  }

  Future<void> _handleMarkDone(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Mark done?',
      body:
          'Locks "${panel.displayExerciseName}" with the sets so far '
          '(${panel.completedSetsCount} of ${panel.totalPlannedSets}).',
      confirmLabel: 'Mark done',
    );
    if (confirmed != true) return;
    bloc.add(FocusModeExerciseMarkedDone(panel.sessionExerciseId));
  }
}

enum _PanelMenuAction { replace, skip, markDone, openVideo }
