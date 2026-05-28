import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_mode_state_views.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_panel_slot.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_pinned_bottom_bar.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_up_next_strip.dart';

class FocusReadyBody extends StatelessWidget {
  const FocusReadyBody({super.key, required this.state});

  final FocusModeReady state;

  @override
  Widget build(BuildContext context) {
    final group = state.groupViewModel;
    final canMutate = !state.mutationInFlight;

    final activeId = group.activeSessionExerciseId;
    final activePanel = activeId == null
        ? null
        : group.panels.firstWhere(
            (p) => p.sessionExerciseId == activeId,
            orElse: () => group.panels.first,
          );

    return Stack(
      children: [
        Column(
          children: [
            FocusUpNextStrip(group: group),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < group.panels.length; i++) ...[
                      FocusPanelSlot(
                        state: state,
                        panel: group.panels[i],
                        role: focusPanelRoleFor(group, i),
                        canMutate: canMutate,
                      ),
                      if (i < group.panels.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
            ),
            FocusPinnedBottomBar(
              state: state,
              activePanel: activePanel,
              canMutate: canMutate,
            ),
          ],
        ),
        if (state.lastTransientError != null)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: FocusTransientErrorBanner(
              error: state.lastTransientError!,
              onDismiss: () => context.read<FocusModeBloc>().add(
                const FocusModeErrorDismissed(),
              ),
            ),
          ),
        if (state.mutationInFlight)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
