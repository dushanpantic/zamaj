import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_state.dart';

import '../../../../support/fake_program_repository.dart';

ProgramEditorBloc _bloc(FakeProgramRepository repo) =>
    ProgramEditorBloc(programRepository: repo);

Future<ProgramEditorEditing> _firstEditing(ProgramEditorBloc bloc) async {
  return await bloc.stream.firstWhere((s) => s is ProgramEditorEditing)
      as ProgramEditorEditing;
}

void main() {
  group('ProgramEditorBloc edit-only', () {
    late FakeProgramRepository repo;

    setUp(() => repo = FakeProgramRepository());

    test('opens an existing program in edit mode', () async {
      final program = repo.seedProgram('Old');
      final bloc = _bloc(repo);
      addTearDown(bloc.close);

      bloc.add(ProgramEditorOpened(programId: program.id));
      final state = await _firstEditing(bloc);

      expect(state.isCreateMode, isFalse);
      expect(state.draft.name, equals('Old'));
      expect(state.draft.programId, equals(program.id));
    });

    test('opening with a null programId never enters a create draft', () async {
      final bloc = _bloc(repo);
      addTearDown(bloc.close);

      bloc.add(const ProgramEditorOpened());
      final state = await bloc.stream.firstWhere(
        (s) => s is! ProgramEditorInitial && s is! ProgramEditorLoading,
      );

      expect(state, isA<ProgramEditorNotFound>());
      expect(repo.programs, isEmpty);
    });

    test('renaming and adding a day never creates a duplicate program',
        () async {
      final program = repo.seedProgram('Old');
      final bloc = _bloc(repo);
      addTearDown(bloc.close);

      bloc.add(ProgramEditorOpened(programId: program.id));
      await _firstEditing(bloc);

      bloc.add(const ProgramEditorNameChanged(name: 'New'));
      bloc.add(const ProgramEditorWorkoutDayAdded(name: 'Day 1'));

      await bloc.stream.firstWhere(
        (s) =>
            s is ProgramEditorEditing &&
            s.draft.workoutDays.any((d) => d.persistedId != null),
      );

      expect(repo.programs, hasLength(1));
      expect(repo.programs.single.name, equals('New'));
      final days = await repo.listWorkoutDaysForProgram(program.id);
      expect(days, hasLength(1));
      expect(days.single.name, equals('Day 1'));
    });

    test('rapid same-type edits apply in order to a single program', () async {
      final program = repo.seedProgram('Old');
      final bloc = _bloc(repo);
      addTearDown(bloc.close);

      bloc.add(ProgramEditorOpened(programId: program.id));
      await _firstEditing(bloc);

      // A burst of rapid name edits, as fast typing would produce.
      bloc.add(const ProgramEditorNameChanged(name: 'A'));
      bloc.add(const ProgramEditorNameChanged(name: 'AB'));
      bloc.add(const ProgramEditorNameChanged(name: 'ABC'));

      // Settle once the final edit has actually been persisted (not just shown
      // optimistically), so we observe the serialized write outcome.
      await bloc.stream.firstWhere(
        (_) => repo.programs.length == 1 && repo.programs.single.name == 'ABC',
      );

      // Serialized into a single writer: one program, last edit wins.
      expect(repo.programs, hasLength(1));
      expect(repo.programs.single.name, equals('ABC'));
    });

    test('a non-DomainError save failure is surfaced, not thrown', () async {
      final program = repo.seedProgram('Old');
      repo.createWorkoutDayError = StateError('Baseline not found');
      final bloc = _bloc(repo);
      addTearDown(bloc.close);

      bloc.add(ProgramEditorOpened(programId: program.id));
      await _firstEditing(bloc);

      bloc.add(const ProgramEditorWorkoutDayAdded(name: 'Day 1'));
      final state =
          await bloc.stream.firstWhere(
                (s) => s is ProgramEditorEditing && s.hadUnexpectedSaveError,
              )
              as ProgramEditorEditing;

      expect(state.hadUnexpectedSaveError, isTrue);
      expect(state.isSaving, isFalse);
    });
  });
}
