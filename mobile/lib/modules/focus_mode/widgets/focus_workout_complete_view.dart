import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_mode_state_views.dart';

/// End-of-workout panel shown when no loggable exercises remain. The user
/// can pop back to the overview screen to review and end the session there.
///
/// A mutation can still fail while this screen is up (e.g. a late undo): when
/// [transientError] is non-null a dismissible banner floats over the panel,
/// reusing the same [FocusTransientErrorBanner] surface the ready body shows so
/// the error is never swallowed on the completion screen.
class FocusWorkoutCompleteView extends StatelessWidget {
  const FocusWorkoutCompleteView({
    super.key,
    required this.workoutDayName,
    required this.onBackToOverview,
    this.transientError,
    this.onDismissError,
  });

  final String workoutDayName;
  final VoidCallback onBackToOverview;
  final DomainError? transientError;
  final VoidCallback? onDismissError;

  @override
  Widget build(BuildContext context) {
    final view = AppStateView(
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

    final error = transientError;
    if (error == null) return view;
    return Stack(
      children: [
        view,
        Positioned(
          top: AppSpacing.sm,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: FocusTransientErrorBanner(
            error: error,
            onDismiss: onDismissError ?? () {},
          ),
        ),
      ],
    );
  }
}
