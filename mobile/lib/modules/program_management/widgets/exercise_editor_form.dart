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
import 'package:zamaj/modules/program_management/widgets/exercise_library_link_section.dart';
import 'package:zamaj/modules/program_management/widgets/measurement_type_selector.dart';
import 'package:zamaj/modules/program_management/widgets/planned_set_row.dart';

class ExerciseEditorForm extends StatelessWidget {
  const ExerciseEditorForm({
    super.key,
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
    final presentedSaveError = lastSaveError == null
        ? null
        : DomainErrorPresenter.present(lastSaveError!);

    return Column(
      children: [
        if (presentedSaveError != null)
          AppNoticeBanner(
            title: presentedSaveError.title,
            body: presentedSaveError.body,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExerciseLibraryLinkSection(draft: draft, bloc: bloc),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: nameController,
                  autofocus: true,
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
                const SectionHeader('Measurement type'),
                const SizedBox(height: AppSpacing.sm),
                MeasurementTypeSelector(
                  selected: draft.measurementType,
                  onChanged: (type) =>
                      bloc.add(ExerciseMeasurementTypeChanged(next: type)),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader('Planned sets'),
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
                  icon: const AppIcon(Icons.add, size: AppIconSize.md),
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
