import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/navigation/exercise_library_routes.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_state.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
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

    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete program?',
      body: 'Deletes the program and all its workout days. Can\'t be undone.',
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
                  ProgramListLoading() => const AppListSkeleton(itemCount: 4),
                  ProgramListFailure() => AppStateView(
                    icon: Icons.error_outline,
                    tone: AppStateTone.error,
                    title: 'Could not load programs',
                    message: 'Check your storage and try again.',
                    primaryAction: AppStateAction(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: () => context.read<ProgramListBloc>().add(
                        const ProgramListRetryRequested(),
                      ),
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
                              ? AppStateView(
                                  icon: Icons.fitness_center_outlined,
                                  title: 'No programs yet',
                                  message:
                                      'Create a program from scratch or '
                                      'import one from text.',
                                  primaryAction: AppStateAction(
                                    label: 'Create empty program',
                                    icon: Icons.add,
                                    onPressed: () => _navigateToEditor(),
                                  ),
                                  secondaryAction: AppStateAction(
                                    label: 'Import from text',
                                    icon: Icons.content_paste_outlined,
                                    onPressed: _navigateToImport,
                                  ),
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
