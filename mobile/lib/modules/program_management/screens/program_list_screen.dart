import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/navigation/exercise_library_routes.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_state.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/program_list_tile.dart';
import 'package:zamaj/modules/workout_day_picker/models/workout_day_picker_args.dart';
import 'package:zamaj/modules/workout_day_picker/navigation/workout_day_picker_routes.dart';
import 'package:zamaj/navigation/widgets/session_in_flight_banner.dart';

class ProgramListScreen extends StatefulWidget {
  const ProgramListScreen({super.key});

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  /// Captured once so the [StreamBuilder] below keeps a single subscription
  /// across bloc rebuilds (`watchActiveSession` mints a fresh controller per
  /// call). Independent of the [SessionInFlightBanner]'s own subscription.
  late final Stream<Session?> _activeSessionStream;

  @override
  void initState() {
    super.initState();
    context.read<ProgramListBloc>().add(const ProgramListRequested());
    _activeSessionStream = context
        .read<SessionRepository>()
        .watchActiveSession();
  }

  Future<void> _navigateToEditor({String? programId}) async {
    await Navigator.pushNamed(
      context,
      ProgramManagementRoutes.programEditor,
      arguments: ProgramEditorArgs(programId: programId),
    );
    if (mounted) {
      context.read<ProgramListBloc>().add(const ProgramListRequested());
    }
  }

  Future<void> _navigateToImport() async {
    await Navigator.pushNamed(context, ProgramManagementRoutes.planImport);
    if (mounted) {
      context.read<ProgramListBloc>().add(const ProgramListRequested());
    }
  }

  void _navigateToLibrary() {
    Navigator.pushNamed(context, ExerciseLibraryRoutes.list);
  }

  Future<void> _onDeleteRequested(String programId) async {
    context.read<ProgramListBloc>().add(
      ProgramListDeleteRequested(programId: programId),
    );

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete program',
      body:
          'This program and all its workout days will be permanently deleted.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!mounted) return;

    if (confirmed == true) {
      context.read<ProgramListBloc>().add(
        ProgramListDeleteConfirmed(programId: programId),
      );
    } else {
      context.read<ProgramListBloc>().add(
        ProgramListDeleteCancelled(programId: programId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            onPressed: _navigateToLibrary,
            icon: const Icon(Icons.library_books_outlined),
            tooltip: 'Exercise library',
          ),
          IconButton(
            onPressed: _navigateToImport,
            icon: const Icon(Icons.content_paste_outlined),
            tooltip: 'Import from text',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New program'),
      ),
      body: Column(
        children: [
          const SessionInFlightBanner(),
          Expanded(
            child: BlocBuilder<ProgramListBloc, ProgramListState>(
              builder: (context, state) {
                return switch (state) {
                  ProgramListInitial() ||
                  ProgramListLoading() => const _LoadingView(),
                  ProgramListFailure(:final error) => _FailureView(
                    error: error,
                    onRetry: () => context.read<ProgramListBloc>().add(
                      const ProgramListRetryRequested(),
                    ),
                  ),
                  ProgramListLoaded(
                    :final programs,
                    :final deletionCandidateId,
                    :final lastDeleteError,
                  ) =>
                    Column(
                      children: [
                        if (lastDeleteError != null)
                          DomainErrorBanner(error: lastDeleteError),
                        Expanded(
                          child: programs.isEmpty
                              ? _EmptyView(
                                  onCreateEmpty: () => _navigateToEditor(),
                                  onImport: _navigateToImport,
                                )
                              : StreamBuilder<Session?>(
                                  stream: _activeSessionStream,
                                  builder: (context, snapshot) {
                                    final activeProgramId = snapshot
                                        .data
                                        ?.snapshot
                                        .workoutDay
                                        .programId;
                                    return _ProgramList(
                                      programs: programs,
                                      deletionCandidateId: deletionCandidateId,
                                      activeProgramId: activeProgramId,
                                      onTap: (program) {
                                        if (program.workoutDayIds.isEmpty) {
                                          _navigateToEditor(
                                            programId: program.id,
                                          );
                                        } else {
                                          Navigator.of(context).pushNamed(
                                            WorkoutDayPickerRoutes.picker,
                                            arguments: WorkoutDayPickerArgs(
                                              programId: program.id,
                                              programName: program.name,
                                            ),
                                          );
                                        }
                                      },
                                      onEdit: (program) => _navigateToEditor(
                                        programId: program.id,
                                      ),
                                      onDeleteRequested: (program) =>
                                          _onDeleteRequested(program.id),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, _) => const _ProgramTileSkeleton(),
    );
  }
}

/// Non-interactive placeholder mirroring [ProgramListTile]'s anatomy (title +
/// metadata rows) for the loading state, using the `_SkeletonBar` idiom from
/// `day_tile.dart`.
class _ProgramTileSkeleton extends StatelessWidget {
  const _ProgramTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(width: 160, color: colors.surfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          _SkeletonBar(width: 110, color: colors.surfaceVariant),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: AppSpacing.md,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load programs',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Check your storage and try again.',
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreateEmpty, required this.onImport});

  final VoidCallback onCreateEmpty;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              color: colors.onSurfaceMuted,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No programs yet',
              style: typography.title.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create a program from scratch or import one from text.',
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateEmpty,
                icon: const Icon(Icons.add),
                label: const Text('Create empty program'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.content_paste_outlined),
                label: const Text('Import from text'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramList extends StatelessWidget {
  const _ProgramList({
    required this.programs,
    required this.deletionCandidateId,
    required this.activeProgramId,
    required this.onTap,
    required this.onEdit,
    required this.onDeleteRequested,
  });

  final List<Program> programs;
  final String? deletionCandidateId;
  final String? activeProgramId;
  final void Function(Program program) onTap;
  final void Function(Program program) onEdit;
  final void Function(Program program) onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ProgramListBloc>().add(const ProgramListRefreshed());
      },
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        itemCount: programs.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final program = programs[index];
          return ProgramListTile(
            program: program,
            onTap: () => onTap(program),
            onEdit: () => onEdit(program),
            onDeleteRequested: () => onDeleteRequested(program),
            isInProgress: program.id == activeProgramId,
            isDeleting: program.id == deletionCandidateId,
          );
        },
      ),
    );
  }
}
