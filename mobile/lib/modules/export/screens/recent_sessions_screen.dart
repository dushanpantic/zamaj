import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/bloc.dart';
import 'package:zamaj/modules/export/models/session_history_item.dart';
import 'package:zamaj/modules/export/widgets/export_preview_sheet.dart';
import 'package:zamaj/modules/export/widgets/session_history_tile.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

/// Recent-sessions list screen. Hosts every completed session for the
/// current program, bucketed into "This week" and "Earlier", and offers a
/// week-export action in the app bar.
class RecentSessionsScreen extends StatelessWidget {
  const RecentSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return BlocBuilder<RecentSessionsBloc, RecentSessionsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(_titleFor(state)),
            actions: state is RecentSessionsLoaded && state.hasWeekSessions
                ? [
                    IconButton(
                      tooltip: 'Export this week',
                      onPressed: () => _showWeekExport(context, state),
                      icon: const Icon(Icons.calendar_view_week),
                    ),
                  ]
                : null,
          ),
          body: _body(context, state),
        );
      },
    );
  }

  String _titleFor(RecentSessionsState state) {
    return switch (state) {
      RecentSessionsInitial() || RecentSessionsLoading() => 'Loading…',
      RecentSessionsProgramNotFound() => 'Program not found',
      RecentSessionsFailure() => 'Could not load sessions',
      RecentSessionsLoaded() => 'Recent sessions',
    };
  }

  Widget _body(BuildContext context, RecentSessionsState state) {
    return switch (state) {
      RecentSessionsInitial() || RecentSessionsLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      RecentSessionsProgramNotFound() => const _NotFoundView(),
      RecentSessionsFailure(:final error) => _FailureView(error: error),
      RecentSessionsLoaded() => _LoadedBody(state: state),
    };
  }

  static void _showWeekExport(
    BuildContext context,
    RecentSessionsLoaded state,
  ) {
    final text = WeekExportFormatter.format(
      weekStart: state.window.start,
      sessions: state.weekSessions,
    );
    ExportPreviewSheet.show(
      context,
      title: 'This week — ${state.programName}',
      text: text,
      shareSubject:
          '${state.programName} — week of '
          '${_isoDate(state.window.start)}',
    );
  }

  static String _isoDate(DateTime d) {
    final l = d.isUtc ? d.toLocal() : d;
    final y = l.year.toString().padLeft(4, '0');
    final m = l.month.toString().padLeft(2, '0');
    final day = l.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final RecentSessionsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const _EmptyView();
    }

    final thisWeek = state.items.where((i) => i.isInThisWeek).toList();
    final earlier = state.items.where((i) => !i.isInThisWeek).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecentSessionsBloc>().add(const RecentSessionsRefreshed());
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          if (thisWeek.isNotEmpty) ...[
            const _SectionHeader('This week'),
            const SizedBox(height: AppSpacing.sm),
            ..._tilesFor(context, thisWeek, state),
          ],
          if (thisWeek.isNotEmpty && earlier.isNotEmpty)
            const SizedBox(height: AppSpacing.xl),
          if (earlier.isNotEmpty) ...[
            const _SectionHeader('Earlier'),
            const SizedBox(height: AppSpacing.sm),
            ..._tilesFor(context, earlier, state),
          ],
        ],
      ),
    );
  }

  List<Widget> _tilesFor(
    BuildContext context,
    List<SessionHistoryItem> items,
    RecentSessionsLoaded state,
  ) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) out.add(const SizedBox(height: AppSpacing.sm));
      final item = items[i];
      out.add(
        SessionHistoryTile(
          key: ValueKey(item.sessionId),
          item: item,
          referenceNow: state.referenceNow,
          onPressed: () => _onTilePressed(context, item, state),
        ),
      );
    }
    return out;
  }

  void _onTilePressed(
    BuildContext context,
    SessionHistoryItem item,
    RecentSessionsLoaded state,
  ) {
    final session = state.sessionsById[item.sessionId];
    if (session == null) return;
    final text = SessionExportFormatter.format(session);
    ExportPreviewSheet.show(
      context,
      title: item.workoutDayName,
      text: text,
      shareSubject: '${item.workoutDayName} — workout',
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Text(
      label,
      style: AppTypography.standard.label.copyWith(
        color: colors.onSurfaceMuted,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: colors.onSurfaceMuted, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No completed sessions yet',
              style: AppTypography.standard.titleSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Finish a workout from the day picker to see it here.',
              style: AppTypography.standard.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: colors.onSurfaceMuted, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Program not found',
              style: AppTypography.standard.titleSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.error});

  final DomainError error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final presented = DomainErrorPresenter.present(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text(
              presented.title,
              style: AppTypography.standard.titleSmall.copyWith(
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              presented.body,
              style: AppTypography.standard.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => context.read<RecentSessionsBloc>().add(
                const RecentSessionsRetried(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
