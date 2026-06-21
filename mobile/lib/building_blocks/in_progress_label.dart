import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// The "in progress" marker shown next to a program or day title whose
/// session is in flight. Quiet orange text rather than a filled pill: the
/// in-progress state is ambient, and the left-edge [InProgressAccentBar]
/// already carries the colour signal, so a loud capsule would shout the same
/// thing twice. Pills stay reserved for the exception states (e.g. Skipped).
class InProgressLabel extends StatelessWidget {
  const InProgressLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Text(
      'In progress',
      style: AppTypography.standard.badge.copyWith(color: colors.primary),
    );
  }
}
