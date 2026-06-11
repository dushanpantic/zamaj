import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';

/// Launches an exercise's reference video externally, surfacing a snackbar
/// if the link can't be opened.
Future<void> openExerciseVideo(BuildContext context, String url) async {
  final launcher = context.read<ExternalLinkLauncher>();
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final result = await launcher.launch(uri);
  if (!context.mounted) return;
  if (result is ExternalLinkFailure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open video: ${result.reason}')),
    );
  }
}

/// Always-visible play affordance for the active focus panel, so a form
/// reference is one tap away without opening the overflow menu.
class FocusVideoButton extends StatelessWidget {
  const FocusVideoButton({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return IconButton(
      onPressed: () => openExerciseVideo(context, videoUrl),
      icon: const Icon(Icons.play_circle_outline),
      iconSize: AppIconSize.xl,
      color: colors.loggableHint,
      tooltip: 'Watch video',
    );
  }
}
