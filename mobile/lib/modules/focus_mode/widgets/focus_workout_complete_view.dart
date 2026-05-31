import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';

/// End-of-workout panel shown when no loggable exercises remain. The user
/// can pop back to the overview screen to review and end the session there.
class FocusWorkoutCompleteView extends StatelessWidget {
  const FocusWorkoutCompleteView({
    super.key,
    required this.workoutDayName,
    required this.onBackToOverview,
  });

  final String workoutDayName;
  final VoidCallback onBackToOverview;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      icon: Icons.check_circle,
      tone: AppStateTone.success,
      title: 'Workout complete',
      message: workoutDayName,
      primaryAction: AppStateAction(
        label: 'Back to overview',
        icon: Icons.list_alt,
        onPressed: onBackToOverview,
      ),
    );
  }
}
