import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/navigation/session_routes.dart';

/// Slim tappable strip surfaced on root screens (e.g. ProgramList) whenever a
/// session is in flight. Tap → resume. Renders nothing when no active session
/// is in progress.
///
/// Placed inline at the top of the body (just under the AppBar) rather than in
/// a Scaffold slot so its intrinsic height is unambiguous on every platform —
/// the banner can never accidentally grab the whole screen.
class SessionInFlightBanner extends StatelessWidget {
  const SessionInFlightBanner({super.key});

  Future<void> _resume(BuildContext context, Session session) async {
    await Navigator.of(
      context,
    ).pushNamed(SessionRoutes.active, arguments: session.id);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SessionRepository>();
    return StreamBuilder<Session?>(
      stream: repo.watchActiveSession(),
      builder: (context, snapshot) {
        final session = snapshot.data;
        if (session == null) return const SizedBox.shrink();
        return SessionInProgressBanner(
          session: session,
          onTap: () => _resume(context, session),
        );
      },
    );
  }
}

/// Presentational "Workout in progress" strip. Renders the [session]'s day name
/// and a Resume affordance; tapping invokes [onTap]. Stateless on purpose so
/// callers own both visibility (whether a session is active) and what Resume
/// does — [SessionInFlightBanner] drives it from a stream and navigates
/// directly, while the day picker drives it from bloc state and routes Resume
/// through its bloc so returning refreshes the screen.
class SessionInProgressBanner extends StatelessWidget {
  const SessionInProgressBanner({
    super.key,
    required this.session,
    required this.onTap,
  });

  final Session session;
  final VoidCallback onTap;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final dayName = session.snapshot.workoutDay.name;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              Container(width: 4, height: _height, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              AppIcon(
                Icons.fitness_center,
                color: colors.primary,
                size: AppIconSize.lg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Workout in progress',
                      style: typography.caption.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                    Text(
                      dayName,
                      style: typography.labelSmall.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Resume',
                style: typography.label.copyWith(color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIcon(
                Icons.arrow_forward,
                color: colors.primary,
                size: AppIconSize.md,
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
