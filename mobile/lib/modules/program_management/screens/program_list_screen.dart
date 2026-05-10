import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_state.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/program_list_tile.dart';

class ProgramListScreen extends StatefulWidget {
  const ProgramListScreen({super.key});

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProgramListBloc>().add(const ProgramListRequested());
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
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        elevation: 0,
      ),
      floatingActionButton: _ProgramListFab(
        onCreateEmpty: () => _navigateToEditor(),
        onImport: _navigateToImport,
      ),
      body: BlocBuilder<ProgramListBloc, ProgramListState>(
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
                        : _ProgramList(
                            programs: programs,
                            deletionCandidateId: deletionCandidateId,
                            onTap: (program) =>
                                _navigateToEditor(programId: program.id),
                            onDeleteRequested: (program) =>
                                _onDeleteRequested(program.id),
                          ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Center(child: CircularProgressIndicator(color: colors.primary));
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
    required this.onTap,
    required this.onDeleteRequested,
  });

  final List<Program> programs;
  final String? deletionCandidateId;
  final void Function(Program program) onTap;
  final void Function(Program program) onDeleteRequested;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.xxxl,
      ),
      itemCount: programs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final program = programs[index];
        return ProgramListTile(
          program: program,
          onTap: () => onTap(program),
          onDeleteRequested: () => onDeleteRequested(program),
          isDeleting: program.id == deletionCandidateId,
        );
      },
    );
  }
}

class _ProgramListFab extends StatelessWidget {
  const _ProgramListFab({required this.onCreateEmpty, required this.onImport});

  final VoidCallback onCreateEmpty;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'fab_import',
          onPressed: onImport,
          backgroundColor: colors.surfaceVariant,
          foregroundColor: colors.onSurface,
          icon: const Icon(Icons.content_paste_outlined),
          label: Text('Import', style: typography.label),
        ),
        const SizedBox(height: AppSpacing.sm),
        FloatingActionButton.extended(
          heroTag: 'fab_create',
          onPressed: onCreateEmpty,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          icon: const Icon(Icons.add),
          label: Text('New program', style: typography.label),
        ),
      ],
    );
  }
}
