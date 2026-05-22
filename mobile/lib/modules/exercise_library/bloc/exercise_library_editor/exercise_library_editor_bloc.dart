import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';

import 'exercise_library_editor_event.dart';
import 'exercise_library_editor_state.dart';

class ExerciseLibraryEditorBloc
    extends Bloc<ExerciseLibraryEditorEvent, ExerciseLibraryEditorState> {
  ExerciseLibraryEditorBloc({
    required ExerciseLibraryRepository exerciseLibraryRepository,
  }) : _repo = exerciseLibraryRepository,
       super(const ExerciseLibraryEditorInitial()) {
    on<ExerciseLibraryEditorOpened>(_onOpened);
    on<ExerciseLibraryEditorNameChanged>(_onNameChanged);
    on<ExerciseLibraryEditorMeasurementTypeChanged>(_onMeasurementTypeChanged);
    on<ExerciseLibraryEditorVideoUrlChanged>(_onVideoUrlChanged);
    on<ExerciseLibraryEditorCuesChanged>(_onCuesChanged);
    on<ExerciseLibraryEditorSavePressed>(_onSavePressed);
    on<ExerciseLibraryEditorArchivePressed>(_onArchivePressed);
    on<ExerciseLibraryEditorUnarchivePressed>(_onUnarchivePressed);
  }

  final ExerciseLibraryRepository _repo;

  LibraryExerciseDraft? _baselineDraft;

  /// Whether the current draft differs from the baseline. Drives the
  /// discard-changes guard on the editor screen.
  bool get isDirty {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return false;
    final baseline = _baselineDraft;
    if (baseline == null) return false;
    return current.draft != baseline;
  }

  Future<void> _onOpened(
    ExerciseLibraryEditorOpened event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    emit(const ExerciseLibraryEditorLoading());

    if (event.libraryExerciseId == null) {
      const draft = LibraryExerciseDraft(
        name: '',
        measurementType: MeasurementType.repBased(),
        videoUrl: '',
        cues: '',
      );
      _baselineDraft = draft;
      emit(
        ExerciseLibraryEditorEditing(
          draft: draft,
          validation: LibraryExerciseDraftValidation.compute(draft),
          persisted: null,
        ),
      );
      return;
    }

    final entry = await _repo.get(event.libraryExerciseId!);
    if (entry == null) {
      emit(
        ExerciseLibraryEditorNotFound(libraryExerciseId: event.libraryExerciseId!),
      );
      return;
    }
    final draft = _entryToDraft(entry);
    _baselineDraft = draft;
    emit(
      ExerciseLibraryEditorEditing(
        draft: draft,
        validation: LibraryExerciseDraftValidation.compute(draft),
        persisted: entry,
      ),
    );
  }

  Future<void> _onNameChanged(
    ExerciseLibraryEditorNameChanged event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return;
    final updated = current.draft.copyWith(name: event.name);
    emit(
      current.copyWith(
        draft: updated,
        validation: LibraryExerciseDraftValidation.compute(updated),
      ),
    );
  }

  Future<void> _onMeasurementTypeChanged(
    ExerciseLibraryEditorMeasurementTypeChanged event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return;
    if (current.isMeasurementTypeLocked) return;
    if (event.next == current.draft.measurementType) return;
    final updated = current.draft.copyWith(measurementType: event.next);
    emit(
      current.copyWith(
        draft: updated,
        validation: LibraryExerciseDraftValidation.compute(updated),
      ),
    );
  }

  Future<void> _onVideoUrlChanged(
    ExerciseLibraryEditorVideoUrlChanged event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return;
    final updated = current.draft.copyWith(videoUrl: event.videoUrl);
    emit(
      current.copyWith(
        draft: updated,
        validation: LibraryExerciseDraftValidation.compute(updated),
      ),
    );
  }

  Future<void> _onCuesChanged(
    ExerciseLibraryEditorCuesChanged event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return;
    final updated = current.draft.copyWith(cues: event.cues);
    emit(
      current.copyWith(
        draft: updated,
        validation: LibraryExerciseDraftValidation.compute(updated),
      ),
    );
  }

  Future<void> _onSavePressed(
    ExerciseLibraryEditorSavePressed event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return;
    final validation = LibraryExerciseDraftValidation.compute(current.draft);
    if (!validation.canSave) {
      emit(current.copyWith(validation: validation));
      return;
    }

    emit(ExerciseLibraryEditorSaving(draft: current.draft));
    try {
      final videoUrl = current.draft.videoUrl.trim();
      final cues = current.draft.cues.trim();
      final persisted = current.persisted;
      final LibraryExercise saved;
      if (persisted == null) {
        saved = await _repo.create(
          name: current.draft.name.trim(),
          measurementType: current.draft.measurementType,
          videoUrl: videoUrl.isEmpty ? null : videoUrl,
          cues: cues.isEmpty ? null : cues,
        );
      } else {
        saved = await _repo.update(
          persisted.copyWith(
            name: current.draft.name.trim(),
            videoUrl: videoUrl.isEmpty ? null : videoUrl,
            cues: cues.isEmpty ? null : cues,
          ),
        );
      }
      emit(ExerciseLibraryEditorSaved(entry: saved));
    } on DomainError catch (e) {
      emit(
        ExerciseLibraryEditorEditing(
          draft: current.draft,
          validation: validation,
          persisted: current.persisted,
          lastError: e,
        ),
      );
    }
  }

  Future<void> _onArchivePressed(
    ExerciseLibraryEditorArchivePressed event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    await _setArchiveState(emit, archive: true);
  }

  Future<void> _onUnarchivePressed(
    ExerciseLibraryEditorUnarchivePressed event,
    Emitter<ExerciseLibraryEditorState> emit,
  ) async {
    await _setArchiveState(emit, archive: false);
  }

  Future<void> _setArchiveState(
    Emitter<ExerciseLibraryEditorState> emit, {
    required bool archive,
  }) async {
    final current = state;
    if (current is! ExerciseLibraryEditorEditing) return;
    final persisted = current.persisted;
    if (persisted == null) return;
    emit(ExerciseLibraryEditorSaving(draft: current.draft));
    try {
      final updated = archive
          ? await _repo.archive(persisted.id)
          : await _repo.unarchive(persisted.id);
      final draft = _entryToDraft(updated);
      _baselineDraft = draft;
      emit(
        ExerciseLibraryEditorEditing(
          draft: draft,
          validation: LibraryExerciseDraftValidation.compute(draft),
          persisted: updated,
        ),
      );
    } on DomainError catch (e) {
      emit(
        ExerciseLibraryEditorEditing(
          draft: current.draft,
          validation: current.validation,
          persisted: current.persisted,
          lastError: e,
        ),
      );
    }
  }

  LibraryExerciseDraft _entryToDraft(LibraryExercise entry) {
    return LibraryExerciseDraft(
      name: entry.name,
      measurementType: entry.measurementType,
      videoUrl: entry.videoUrl ?? '',
      cues: entry.cues ?? '',
    );
  }
}
