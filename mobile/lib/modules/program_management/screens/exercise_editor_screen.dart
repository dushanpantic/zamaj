import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/relative_date_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/exercise_editor_scaffolds.dart';

class ExerciseEditorScreen extends StatefulWidget {
  const ExerciseEditorScreen({super.key, required this.args});

  final ExerciseArgs args;

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _plannedRestController;
  late final TextEditingController _notesController;
  late final TextEditingController _videoUrlController;

  bool _controllersInitialized = false;
  bool _didInitialControllerSync = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _plannedRestController = TextEditingController();
    _notesController = TextEditingController();
    _videoUrlController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllersInitialized) {
      context.read<ExerciseEditorBloc>().add(
        ExerciseEditorOpened(exerciseId: widget.args.exerciseId),
      );
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plannedRestController.dispose();
    _notesController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _syncControllers(ExerciseDraft draft) {
    _syncLinkProvidedFields(draft);

    final restText = draft.plannedRestSeconds?.toString() ?? '';
    if (_plannedRestController.text != restText) {
      _plannedRestController.text = restText;
    }

    final notes = draft.metadata.notes ?? '';
    if (_notesController.text != notes) {
      _notesController.text = notes;
    }
  }

  /// Syncs only the fields a library link can rewrite (name, video URL).
  /// Planned rest must stay untouched here: its source of truth is the raw
  /// input tracked inside the bloc, not the draft, so rewriting it from the
  /// draft would revert unsaved typing.
  void _syncLinkProvidedFields(ExerciseDraft draft) {
    if (_nameController.text != draft.name) {
      _nameController.value = _nameController.value.copyWith(
        text: draft.name,
        selection: TextSelection.collapsed(offset: draft.name.length),
      );
    }

    final videoUrl = draft.metadata.videoUrl ?? '';
    if (_videoUrlController.text != videoUrl) {
      _videoUrlController.text = videoUrl;
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Discard changes?',
      body: 'Your edits will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    return confirmed == true;
  }

  /// Surfaces the overwrite-confirm dialog for a pending recent-history apply.
  /// The lifter can tap-apply and then Save without leaving the screen, which
  /// never invokes the discard guard — so this gate is the only thing
  /// protecting already-entered set data on a pre-fill.
  Future<void> _confirmHistoryApply(
    BuildContext context,
    CapHistoryEntry entry,
  ) async {
    final bloc = context.read<ExerciseEditorBloc>();
    final loggedOn = RelativeDateFormatter.formatAbsolute(entry.date.toLocal());
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Replace planned sets?',
      body:
          'This replaces your current planned sets with what you logged on '
          '$loggedOn.',
      confirmLabel: 'Replace',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    // The dialog awaited above; the route (and its scoped bloc) may have been
    // popped meanwhile. Guard before dispatching to a possibly-closed bloc.
    if (!context.mounted) return;
    bloc.add(
      confirmed == true
          ? const RecentHistoryApplyConfirmed()
          : const RecentHistoryApplyDismissed(),
    );
  }

  Future<void> _handlePop(bool didPop, BuildContext context) async {
    if (didPop) return;
    final shouldDiscard = await _confirmDiscard(context);
    if (!context.mounted) return;
    if (shouldDiscard) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExerciseEditorBloc, ExerciseEditorState>(
      listenWhen: (previous, current) {
        if (current is ExerciseEditorSaved) return true;
        if (current is ExerciseEditorVideoLinkError) return true;
        if (current is ExerciseEditorEditing) {
          if (previous is! ExerciseEditorEditing) return true;
          // A pre-fill over user-entered sets just stashed a pending apply —
          // surface the overwrite-confirm dialog.
          if (current.pendingHistoryApply != null &&
              previous.pendingHistoryApply != current.pendingHistoryApply) {
            return true;
          }
          // The bloc rewrote controller-backed text (e.g. library link with
          // "update row") — resync, but never on plain typing emissions.
          return previous.controllerSyncRevision !=
              current.controllerSyncRevision;
        }
        return false;
      },
      listener: (context, state) {
        if (state is ExerciseEditorSaved) {
          Navigator.of(context).pop();
          return;
        }

        if (state is ExerciseEditorVideoLinkError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: ${state.reason}')),
          );
          return;
        }

        if (state is ExerciseEditorEditing) {
          final pending = state.pendingHistoryApply;
          if (pending != null) {
            _confirmHistoryApply(context, pending);
            return;
          }
          if (!_controllersInitialized) return;
          if (_didInitialControllerSync) {
            _syncLinkProvidedFields(state.draft);
          } else {
            _syncControllers(state.draft);
            _didInitialControllerSync = true;
          }
        }
      },
      builder: (context, state) {
        final bloc = context.read<ExerciseEditorBloc>();
        final scaffold = switch (state) {
          ExerciseEditorInitial() => const ExerciseEditorLoadingScaffold(),
          ExerciseEditorLoading() => const ExerciseEditorLoadingScaffold(),
          ExerciseEditorNotFound(:final exerciseId) =>
            ExerciseEditorNotFoundScaffold(exerciseId: exerciseId),
          ExerciseEditorSaving(:final draft) => ExerciseEditorScaffold(
            nameController: _nameController,
            plannedRestController: _plannedRestController,
            notesController: _notesController,
            videoUrlController: _videoUrlController,
            draft: draft,
            validation: const ExerciseDraftValidation(
              isNameValid: true,
              isPlannedRestValid: true,
              isVideoUrlValid: true,
              isNotesValid: true,
              isSetCountValid: true,
              areSetsValid: true,
            ),
            isSaving: true,
            lastSaveError: null,
          ),
          ExerciseEditorEditing(
            :final draft,
            :final validation,
            :final lastSaveError,
            :final recentHistory,
          ) =>
            ExerciseEditorScaffold(
              nameController: _nameController,
              plannedRestController: _plannedRestController,
              notesController: _notesController,
              videoUrlController: _videoUrlController,
              draft: draft,
              validation: validation,
              isSaving: false,
              lastSaveError: lastSaveError,
              recentHistory: recentHistory,
            ),
          ExerciseEditorSaved() => const ExerciseEditorLoadingScaffold(),
          ExerciseEditorVideoLinkError(:final draft, :final validation) =>
            ExerciseEditorScaffold(
              nameController: _nameController,
              plannedRestController: _plannedRestController,
              notesController: _notesController,
              videoUrlController: _videoUrlController,
              draft: draft,
              validation: validation,
              isSaving: false,
              lastSaveError: null,
            ),
        };

        return PopScope(
          canPop: !bloc.isDirty,
          onPopInvokedWithResult: (didPop, _) => _handlePop(didPop, context),
          child: scaffold,
        );
      },
    );
  }
}
