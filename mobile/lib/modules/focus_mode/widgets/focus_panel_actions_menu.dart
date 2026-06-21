import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_video_button.dart';

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
    // The single adaptive terminal action is offered only while the exercise is
    // still unfinished (`isLoggable`); an already-terminal panel offers no
    // terminal action, only its non-terminal items.
    final canEndOrSkip = panel.isLoggable;
    final hasSets = panel.completedSetsCount > 0;
    return PopupMenuButton<_PanelMenuAction>(
      icon: Icon(Icons.more_vert, color: colors.onSurface),
      onSelected: (action) {
        switch (action) {
          case _PanelMenuAction.endOrSkip:
            _handleEndOrSkip(context);
          case _PanelMenuAction.openVideo:
            if (hasVideo) openExerciseVideo(context, videoUrl);
        }
      },
      itemBuilder: (context) => [
        if (canEndOrSkip)
          PopupMenuItem(
            value: _PanelMenuAction.endOrSkip,
            child: ListTile(
              leading: Icon(hasSets ? Icons.flag_outlined : Icons.skip_next),
              title: Text(hasSets ? 'End exercise' : 'Skip exercise'),
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

  /// The single adaptive terminal action. With no sets logged it reads as a
  /// destructive "Skip exercise"; with some sets it reads as "End exercise" and
  /// states the consequence with counts. Both fire [FocusModeExerciseSkipped].
  Future<void> _handleEndOrSkip(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final hasSets = panel.completedSetsCount > 0;
    final name = panel.displayExerciseName;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: hasSets ? 'End exercise?' : 'Skip exercise?',
      body: hasSets
          ? 'You\'ve logged ${panel.completedSetsCount} of '
                '${panel.totalPlannedSets} sets for "$name". You won\'t be able '
                'to log the remaining sets — logged values stay editable.'
          : 'Marks "$name" skipped and moves on. This session only.',
      confirmLabel: hasSets ? 'End exercise' : 'Skip',
      isDestructive: !hasSets,
    );
    if (confirmed != true) return;
    bloc.add(FocusModeExerciseSkipped(panel.sessionExerciseId));
  }
}

enum _PanelMenuAction { endOrSkip, openVideo }
