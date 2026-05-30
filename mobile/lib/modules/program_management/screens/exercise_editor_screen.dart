import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
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
    if (_nameController.text != draft.name) {
      _nameController.value = _nameController.value.copyWith(
        text: draft.name,
        selection: TextSelection.collapsed(offset: draft.name.length),
      );
    }

    final restText = draft.plannedRestSeconds?.toString() ?? '';
    if (_plannedRestController.text != restText) {
      _plannedRestController.text = restText;
    }

    final notes = draft.metadata.notes ?? '';
    if (_notesController.text != notes) {
      _notesController.text = notes;
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
      body: 'Your edits to this exercise will be lost.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
      isDestructive: true,
    );
    return confirmed == true;
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
        if (current is ExerciseEditorEditing &&
            previous is! ExerciseEditorEditing) {
          return true;
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
          if (!_controllersInitialized) return;
          _syncControllers(state.draft);
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
