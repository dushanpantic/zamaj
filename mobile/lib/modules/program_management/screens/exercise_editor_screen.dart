import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/measurement_type_selector.dart';
import 'package:zamaj/modules/program_management/widgets/planned_set_row.dart';

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
  bool _pendingDialogShown = false;

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

  Future<void> _showMeasurementChangeDialog(
    BuildContext context,
    MeasurementType pending,
  ) async {
    if (_pendingDialogShown) return;
    _pendingDialogShown = true;

    final label = switch (pending) {
      RepBasedMeasurement() => 'rep-based',
      TimeBasedMeasurement() => 'time-based',
    };

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Change measurement type',
      body:
          'Switching to $label will reset all planned set values. This cannot be undone.',
      confirmLabel: 'Switch',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    _pendingDialogShown = false;

    if (!context.mounted) return;

    if (confirmed == true) {
      context.read<ExerciseEditorBloc>().add(
        const ExerciseMeasurementTypeConfirmed(),
      );
    } else {
      context.read<ExerciseEditorBloc>().add(
        const ExerciseMeasurementTypeCancelled(),
      );
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
        if (current is ExerciseEditorEditing &&
            current.pendingMeasurementChange != null &&
            (previous is! ExerciseEditorEditing ||
                previous.pendingMeasurementChange == null)) {
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

          if (state.pendingMeasurementChange != null) {
            _showMeasurementChangeDialog(
              context,
              state.pendingMeasurementChange!,
            );
          }
        }
      },
      builder: (context, state) {
        return switch (state) {
          ExerciseEditorInitial() => const _LoadingScaffold(),
          ExerciseEditorLoading() => const _LoadingScaffold(),
          ExerciseEditorNotFound(:final exerciseId) => _NotFoundScaffold(
            exerciseId: exerciseId,
          ),
          ExerciseEditorSaving(:final draft) => _EditorScaffold(
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
            _EditorScaffold(
              nameController: _nameController,
              plannedRestController: _plannedRestController,
              notesController: _notesController,
              videoUrlController: _videoUrlController,
              draft: draft,
              validation: validation,
              isSaving: false,
              lastSaveError: lastSaveError,
            ),
          ExerciseEditorSaved() => const _LoadingScaffold(),
          ExerciseEditorVideoLinkError(:final draft, :final validation) =>
            _EditorScaffold(
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
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Scaffold(
      body: Center(child: CircularProgressIndicator(color: colors.primary)),
    );
  }
}

class _NotFoundScaffold extends StatelessWidget {
  const _NotFoundScaffold({required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Exercise not found.',
                style: typography.titleSmall.copyWith(
                  color: colors.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({
    required this.nameController,
    required this.plannedRestController,
    required this.notesController,
    required this.videoUrlController,
    required this.draft,
    required this.validation,
    required this.isSaving,
    required this.lastSaveError,
  });

  final TextEditingController nameController;
  final TextEditingController plannedRestController;
  final TextEditingController notesController;
  final TextEditingController videoUrlController;
  final ExerciseDraft draft;
  final ExerciseDraftValidation validation;
  final bool isSaving;
  final DomainError? lastSaveError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final bloc = context.read<ExerciseEditorBloc>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Exercise',
          style: typography.title.copyWith(color: colors.onBackground),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: validation.canSave && !isSaving
                  ? () => bloc.add(const ExerciseSavePressed())
                  : null,
              child: Text(
                'Save',
                style: typography.label.copyWith(
                  color: validation.canSave && !isSaving
                      ? colors.primary
                      : colors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _EditorBody(
            nameController: nameController,
            plannedRestController: plannedRestController,
            notesController: notesController,
            videoUrlController: videoUrlController,
            draft: draft,
            validation: validation,
            lastSaveError: lastSaveError,
          ),
          if (isSaving)
            ColoredBox(
              color: colors.background.withValues(alpha: 0.6),
              child: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditorBody extends StatelessWidget {
  const _EditorBody({
    required this.nameController,
    required this.plannedRestController,
    required this.notesController,
    required this.videoUrlController,
    required this.draft,
    required this.validation,
    required this.lastSaveError,
  });

  final TextEditingController nameController;
  final TextEditingController plannedRestController;
  final TextEditingController notesController;
  final TextEditingController videoUrlController;
  final ExerciseDraft draft;
  final ExerciseDraftValidation validation;
  final DomainError? lastSaveError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final bloc = context.read<ExerciseEditorBloc>();

    return Column(
      children: [
        if (lastSaveError != null) DomainErrorBanner(error: lastSaveError!),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Exercise name',
                    errorText:
                        !validation.isNameValid &&
                            nameController.text.isNotEmpty
                        ? 'Name must be 1–100 characters'
                        : null,
                  ),
                  onChanged: (value) =>
                      bloc.add(ExerciseNameChanged(name: value)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Measurement type',
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                MeasurementTypeSelector(
                  selected: draft.measurementType,
                  onChanged: (type) =>
                      bloc.add(ExerciseMeasurementTypeRequested(next: type)),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Planned sets',
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: (oldIndex, newIndex) {
                    final ids = draft.sets.map((s) => s.draftId).toList();
                    if (newIndex > oldIndex) newIndex -= 1;
                    final moved = ids.removeAt(oldIndex);
                    ids.insert(newIndex, moved);
                    bloc.add(PlannedSetReordered(orderedSetDraftIds: ids));
                  },
                  children: [
                    for (var i = 0; i < draft.sets.length; i++)
                      PlannedSetRow(
                        key: ValueKey(draft.sets[i].draftId),
                        setDraft: draft.sets[i],
                        reorderIndex: i,
                        onWeightChanged: (raw) => bloc.add(
                          PlannedSetWeightChanged(
                            setDraftId: draft.sets[i].draftId,
                            rawInput: raw,
                          ),
                        ),
                        onRepsChanged: (raw) => bloc.add(
                          PlannedSetRepsChanged(
                            setDraftId: draft.sets[i].draftId,
                            rawInput: raw,
                          ),
                        ),
                        onDurationChanged: (raw) => bloc.add(
                          PlannedSetDurationChanged(
                            setDraftId: draft.sets[i].draftId,
                            rawInput: raw,
                          ),
                        ),
                        onDelete: () => bloc.add(
                          PlannedSetDeleted(setDraftId: draft.sets[i].draftId),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: draft.sets.length < 20
                      ? () => bloc.add(const PlannedSetAdded())
                      : null,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add set'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: plannedRestController,
                  keyboardType: TextInputType.number,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Planned rest (seconds)',
                    errorText: !validation.isPlannedRestValid
                        ? 'Enter a valid rest duration (0–3600 seconds)'
                        : null,
                  ),
                  onChanged: (value) =>
                      bloc.add(ExercisePlannedRestChanged(rawInput: value)),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: notesController,
                  maxLines: 4,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                    errorText: !validation.isNotesValid
                        ? 'Notes must be 2000 characters or fewer'
                        : null,
                  ),
                  onChanged: (value) => bloc.add(
                    ExerciseNotesChanged(notes: value.isEmpty ? null : value),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: videoUrlController,
                        keyboardType: TextInputType.url,
                        style: typography.body.copyWith(
                          color: colors.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Video URL',
                          errorText: !validation.isVideoUrlValid
                              ? 'Enter a valid URL'
                              : null,
                        ),
                        onChanged: (value) => bloc.add(
                          ExerciseVideoUrlChanged(
                            videoUrl: value.isEmpty ? null : value,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          color:
                              videoUrlController.text.isNotEmpty &&
                                  validation.isVideoUrlValid
                              ? colors.primary
                              : colors.onSurfaceMuted,
                        ),
                        tooltip: 'Open video',
                        onPressed:
                            videoUrlController.text.isNotEmpty &&
                                validation.isVideoUrlValid
                            ? () => bloc.add(const ExerciseVideoUrlActivated())
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
