import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/bloc.dart';
import 'package:zamaj/modules/export/models/session_detail_args.dart';
import 'package:zamaj/modules/export/models/session_history_item.dart';
import 'package:zamaj/modules/export/navigation/export_routes.dart';
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
            // Title is a stable anchor, not a status line: state ('Loading…',
            // 'Could not load sessions', 'Program not found') lives in the body
            // AppStateView only.
            title: const Text('Recent sessions'),
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

  Widget _body(BuildContext context, RecentSessionsState state) {
    return switch (state) {
      RecentSessionsInitial() ||
      RecentSessionsLoading() => const AppListSkeleton(),
      RecentSessionsProgramNotFound() => AppStateView(
        icon: Icons.search_off,
        title: 'Program not found',
        primaryAction: AppStateAction(
          label: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      RecentSessionsFailure(:final error) => _failureView(context, error),
      RecentSessionsLoaded() => _LoadedBody(state: state),
    };
  }

  Widget _failureView(BuildContext context, DomainError error) {
    final presented = DomainErrorPresenter.present(error);
    return AppStateView(
      icon: Icons.error_outline,
      tone: AppStateTone.error,
      title: presented.title,
      message: presented.body,
      primaryAction: AppStateAction(
        label: 'Retry',
        onPressed: () => context.read<RecentSessionsBloc>().add(
          const RecentSessionsRetried(),
        ),
      ),
    );
  }

  static void _showWeekExport(
    BuildContext context,
    RecentSessionsLoaded state,
  ) {
    ExportPreviewSheet.show(
      context,
      title: 'This week, ${state.programName}',
      buildText: (includeWarmups) => WeekExportFormatter.format(
        weekStart: state.window.start,
        sessions: state.weekSessions,
        includeWarmups: includeWarmups,
      ),
      shareSubject:
          '${state.programName}, week of '
          '${DateFormatter.isoDate(state.window.start.toLocal())}',
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final RecentSessionsLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const AppStateView(
        icon: Icons.history,
        title: 'No completed sessions yet',
        message: 'Finish a workout from the day picker to see it here.',
      );
    }

    final thisWeek = state.items.where((i) => i.isInThisWeek).toList();
    final earlier = state.items.where((i) => !i.isInThisWeek).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecentSessionsBloc>().add(const RecentSessionsRefreshed());
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          if (thisWeek.isNotEmpty) ...[
            const SectionHeader('This week'),
            const SizedBox(height: AppSpacing.sm),
            ..._tilesFor(context, thisWeek, state),
          ],
          if (thisWeek.isNotEmpty && earlier.isNotEmpty)
            const SizedBox(height: AppSpacing.xl),
          if (earlier.isNotEmpty) ...[
            const SectionHeader('Earlier'),
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
          onDelete: () => _onDeleteRequested(context, item),
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
    // The detail screen now hosts per-session text export behind its own share
    // icon; tapping a tile opens the read-only review rather than the sheet.
    Navigator.of(context).pushNamed(
      ExportRoutes.sessionDetail,
      arguments: SessionDetailArgs(session: session),
    );
  }

  Future<void> _onDeleteRequested(
    BuildContext context,
    SessionHistoryItem item,
  ) async {
    final bloc = context.read<RecentSessionsBloc>();
    final confirmed = await _confirmDelete(context, item);
    if (confirmed != true) return;
    bloc.add(RecentSessionsDeleteRequested(item.sessionId));
  }

  Future<bool?> _confirmDelete(BuildContext context, SessionHistoryItem item) {
    return AppConfirmDialog.show(
      context: context,
      title: 'Delete session?',
      body:
          'Removes "${item.workoutDayName}" and all its logged sets. '
          'Can\'t be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
  }
}
