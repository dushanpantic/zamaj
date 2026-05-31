import 'package:flutter/material.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_current_values_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_panel_actions_menu.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_panel_header.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_planned_and_last.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_set_progress.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_video_button.dart';

/// Full editor for the currently active panel — pips, planned/last,
/// numeric hero + bump rows, 3-dot menu. The LOG SET button lives in the
/// pinned bottom bar, not inside the card.
class FocusCurrentPanelCard extends StatelessWidget {
  const FocusCurrentPanelCard({
    super.key,
    required this.state,
    required this.panel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final accent = colors.loggableHint;
    final videoUrl = panel.displayMetadata?.videoUrl;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    return Container(
      key: ValueKey('current-panel-${panel.sessionExerciseId}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: AppOpacity.recede4),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: accent.withValues(alpha: AppOpacity.borderTint),
          width: AppStroke.emphasis,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: FocusPanelHeader(panel: panel)),
              if (hasVideo) FocusVideoButton(videoUrl: videoUrl),
              FocusPanelActionsMenu(
                state: state,
                panel: panel,
                showVideoItem: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FocusSetProgress(
            completed: panel.completedSetsCount,
            total: panel.totalPlannedSets,
            currentIndex: panel.currentSetIndex,
          ),
          const SizedBox(height: AppSpacing.md),
          FocusPlannedAndLast(panel: panel),
          const SizedBox(height: AppSpacing.md),
          FocusCurrentValuesPanel(
            state: state,
            panel: panel,
            canMutate: canMutate,
          ),
        ],
      ),
    );
  }
}
