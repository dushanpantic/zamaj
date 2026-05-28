import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';

/// App-bar action that opens a "switch to" picker, listing every other
/// visible group in the session. Tapping an option dispatches
/// [FocusModeGroupSwitched] and the panels refresh in place.
class FocusSwitchExerciseButton extends StatelessWidget {
  const FocusSwitchExerciseButton({super.key, required this.state});

  final FocusModeReady state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final options = FocusModeAssembler.listSwitchOptions(
      state.sessionState,
      currentAnchorId: state.anchorSessionExerciseId,
    );
    if (options.length <= 1) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Switch exercise',
      icon: Icon(Icons.swap_vert, color: colors.onSurface),
      onSelected: (anchorId) =>
          context.read<FocusModeBloc>().add(FocusModeGroupSwitched(anchorId)),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.anchorSessionExerciseId,
            enabled: !option.isCurrent,
            child: Row(
              children: [
                Icon(
                  option.isSuperset ? Icons.link : Icons.fitness_center,
                  size: 18,
                  color: colors.onSurfaceMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(option.label)),
                if (option.isCurrent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '(current)',
                    style: TextStyle(color: colors.onSurfaceMuted),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
