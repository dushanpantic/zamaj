import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/exercise_editor_form.dart';

class ExerciseEditorLoadingScaffold extends StatelessWidget {
  const ExerciseEditorLoadingScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: const AppFormSkeleton());
  }
}

class ExerciseEditorNotFoundScaffold extends StatelessWidget {
  const ExerciseEditorNotFoundScaffold({super.key, required this.exerciseId});

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
              AppIcon(
                Icons.error_outline,
                color: colors.error,
                size: AppIconSize.errorState,
              ),
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

class ExerciseEditorScaffold extends StatelessWidget {
  const ExerciseEditorScaffold({
    super.key,
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
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: Center(child: AppInlineSpinner()),
            ),
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
                ),
              ),
            ),
          ),
        ],
      ),
      // While saving, disable the form (the inline app-bar spinner is the only
      // progress chrome — no scrim). On failure the bloc returns to the editing
      // state with isSaving false, re-enabling the form with edits intact and
      // surfacing lastSaveError via the form's AppNoticeBanner.
      body: AbsorbPointer(
        absorbing: isSaving,
        child: ExerciseEditorForm(
          nameController: nameController,
          plannedRestController: plannedRestController,
          notesController: notesController,
          videoUrlController: videoUrlController,
          draft: draft,
          validation: validation,
          lastSaveError: lastSaveError,
        ),
      ),
    );
  }
}
