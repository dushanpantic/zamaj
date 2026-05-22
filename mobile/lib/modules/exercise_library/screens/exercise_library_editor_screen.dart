import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/bloc/exercise_library_editor/bloc.dart';
import 'package:zamaj/modules/exercise_library/models/exercise_library_args.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/measurement_type_selector.dart';

class ExerciseLibraryEditorScreen extends StatefulWidget {
  const ExerciseLibraryEditorScreen({super.key, required this.args});

  final ExerciseLibraryEditorArgs args;

  @override
  State<ExerciseLibraryEditorScreen> createState() =>
      _ExerciseLibraryEditorScreenState();
}

class _ExerciseLibraryEditorScreenState
    extends State<ExerciseLibraryEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _cuesController;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _videoUrlController = TextEditingController();
    _cuesController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllersInitialized) {
      context.read<ExerciseLibraryEditorBloc>().add(
        ExerciseLibraryEditorOpened(
          libraryExerciseId: widget.args.libraryExerciseId,
        ),
      );
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _videoUrlController.dispose();
    _cuesController.dispose();
    super.dispose();
  }

  void _syncControllers(LibraryExerciseDraft draft) {
    if (_nameController.text != draft.name) {
      _nameController.value = _nameController.value.copyWith(
        text: draft.name,
        selection: TextSelection.collapsed(offset: draft.name.length),
      );
    }
    if (_videoUrlController.text != draft.videoUrl) {
      _videoUrlController.text = draft.videoUrl;
    }
    if (_cuesController.text != draft.cues) {
      _cuesController.text = draft.cues;
    }
  }

  Future<bool> _confirmDiscard(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Discard changes?',
      body: 'Your edits to this library entry will be lost.',
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

  Future<void> _confirmArchive(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Archive entry',
      body:
          'Archive this entry? It stays linked to past data but stops appearing '
          'in the picker. You can restore it later.',
      confirmLabel: 'Archive',
    );
    if (!context.mounted) return;
    if (confirmed == true) {
      context.read<ExerciseLibraryEditorBloc>().add(
        const ExerciseLibraryEditorArchivePressed(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExerciseLibraryEditorBloc, ExerciseLibraryEditorState>(
      listenWhen: (previous, current) {
        if (current is ExerciseLibraryEditorSaved) return true;
        if (current is ExerciseLibraryEditorEditing &&
            previous is! ExerciseLibraryEditorEditing) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is ExerciseLibraryEditorSaved) {
          Navigator.of(context).pop(state.entry);
          return;
        }
        if (state is ExerciseLibraryEditorEditing) {
          _syncControllers(state.draft);
        }
      },
      builder: (context, state) {
        final bloc = context.read<ExerciseLibraryEditorBloc>();
        final scaffold = switch (state) {
          ExerciseLibraryEditorInitial() ||
          ExerciseLibraryEditorLoading() => const _LoadingScaffold(),
          ExerciseLibraryEditorNotFound(:final libraryExerciseId) =>
            _NotFoundScaffold(libraryExerciseId: libraryExerciseId),
          ExerciseLibraryEditorSaving(:final draft) => _EditorScaffold(
            nameController: _nameController,
            videoUrlController: _videoUrlController,
            cuesController: _cuesController,
            draft: draft,
            validation: const LibraryExerciseDraftValidation(
              isNameValid: true,
              isVideoUrlValid: true,
              areCuesValid: true,
            ),
            isCreate: false,
            isMeasurementTypeLocked: true,
            isArchived: false,
            isSaving: true,
            lastError: null,
            onArchive: () => _confirmArchive(context),
          ),
          ExerciseLibraryEditorEditing(
            :final draft,
            :final validation,
            :final lastError,
            :final isCreate,
            :final isMeasurementTypeLocked,
            :final isArchived,
          ) =>
            _EditorScaffold(
              nameController: _nameController,
              videoUrlController: _videoUrlController,
              cuesController: _cuesController,
              draft: draft,
              validation: validation,
              isCreate: isCreate,
              isMeasurementTypeLocked: isMeasurementTypeLocked,
              isArchived: isArchived,
              isSaving: false,
              lastError: lastError,
              onArchive: () => _confirmArchive(context),
            ),
          ExerciseLibraryEditorSaved() => const _LoadingScaffold(),
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
  const _NotFoundScaffold({required this.libraryExerciseId});

  final String libraryExerciseId;

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
                'Library entry not found.',
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
    required this.videoUrlController,
    required this.cuesController,
    required this.draft,
    required this.validation,
    required this.isCreate,
    required this.isMeasurementTypeLocked,
    required this.isArchived,
    required this.isSaving,
    required this.lastError,
    required this.onArchive,
  });

  final TextEditingController nameController;
  final TextEditingController videoUrlController;
  final TextEditingController cuesController;
  final LibraryExerciseDraft draft;
  final LibraryExerciseDraftValidation validation;
  final bool isCreate;
  final bool isMeasurementTypeLocked;
  final bool isArchived;
  final bool isSaving;
  final DomainError? lastError;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final bloc = context.read<ExerciseLibraryEditorBloc>();
    final canSave = validation.canSave && !isSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCreate ? 'New library entry' : 'Edit library entry',
          style: typography.title.copyWith(color: colors.onBackground),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              onPressed: canSave
                  ? () => bloc.add(const ExerciseLibraryEditorSavePressed())
                  : null,
              child: Text(
                'Save',
                style: typography.label.copyWith(
                  color: canSave ? colors.primary : colors.onSurfaceMuted,
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
            videoUrlController: videoUrlController,
            cuesController: cuesController,
            draft: draft,
            validation: validation,
            isMeasurementTypeLocked: isMeasurementTypeLocked,
            isArchived: isArchived,
            isCreate: isCreate,
            lastError: lastError,
            onArchive: onArchive,
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
    required this.videoUrlController,
    required this.cuesController,
    required this.draft,
    required this.validation,
    required this.isMeasurementTypeLocked,
    required this.isArchived,
    required this.isCreate,
    required this.lastError,
    required this.onArchive,
  });

  final TextEditingController nameController;
  final TextEditingController videoUrlController;
  final TextEditingController cuesController;
  final LibraryExerciseDraft draft;
  final LibraryExerciseDraftValidation validation;
  final bool isMeasurementTypeLocked;
  final bool isArchived;
  final bool isCreate;
  final DomainError? lastError;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final bloc = context.read<ExerciseLibraryEditorBloc>();

    return Column(
      children: [
        if (lastError != null) DomainErrorBanner(error: lastError!),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: isCreate,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText:
                        !validation.isNameValid && nameController.text.isNotEmpty
                        ? 'Name must be 1–80 characters'
                        : null,
                  ),
                  onChanged: (value) =>
                      bloc.add(ExerciseLibraryEditorNameChanged(name: value)),
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
                  enabled: !isMeasurementTypeLocked,
                  onChanged: (type) => bloc.add(
                    ExerciseLibraryEditorMeasurementTypeChanged(next: type),
                  ),
                ),
                if (isMeasurementTypeLocked) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Locked after first save. Archive and re-create if this needs to change.',
                    style: typography.caption.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: videoUrlController,
                  keyboardType: TextInputType.url,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Video URL (optional)',
                    errorText: !validation.isVideoUrlValid
                        ? 'Enter a valid http(s) URL'
                        : null,
                  ),
                  onChanged: (value) => bloc.add(
                    ExerciseLibraryEditorVideoUrlChanged(videoUrl: value),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: cuesController,
                  maxLines: 6,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Cues (optional)',
                    alignLabelWithHint: true,
                    errorText: !validation.areCuesValid
                        ? 'Cues must be 2000 characters or fewer'
                        : null,
                  ),
                  onChanged: (value) =>
                      bloc.add(ExerciseLibraryEditorCuesChanged(cues: value)),
                ),
                if (!isCreate) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: isArchived
                        ? FilledButton.icon(
                            onPressed: () => bloc.add(
                              const ExerciseLibraryEditorUnarchivePressed(),
                            ),
                            icon: const Icon(Icons.unarchive_outlined),
                            label: const Text('Restore from archive'),
                          )
                        : OutlinedButton.icon(
                            onPressed: onArchive,
                            icon: Icon(
                              Icons.archive_outlined,
                              color: colors.warning,
                            ),
                            label: Text(
                              'Archive entry',
                              style: TextStyle(color: colors.warning),
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
