import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_list/program_list_state.dart';
import 'package:zamaj/modules/program_management/services/program_name_rules.dart';

import '../../../../support/fake_program_repository.dart';

/// Awaits the first [ProgramListLoaded] matching [test], failing fast with a
/// readable timeout rather than hanging until the global harness timeout.
Future<ProgramListLoaded> _awaitLoaded(
  ProgramListBloc bloc,
  bool Function(ProgramListLoaded) test,
) async =>
    await bloc.stream
            .firstWhere((s) => s is ProgramListLoaded && test(s))
            .timeout(const Duration(seconds: 5))
        as ProgramListLoaded;

void main() {
  group('ProgramListBloc create', () {
    late FakeProgramRepository repo;
    late ProgramListBloc bloc;

    setUp(() {
      repo = FakeProgramRepository();
      bloc = ProgramListBloc(programRepository: repo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('creates exactly one program with the given name', () async {
      bloc.add(const ProgramCreateRequested(name: 'ASDF'));
      await _awaitLoaded(bloc, (s) => s.programs.isNotEmpty);

      expect(repo.createProgramCalls, equals(['ASDF']));
      expect(repo.programs, hasLength(1));
      expect(repo.programs.single.name, equals('ASDF'));
    });

    test('surfaces the created program id for navigation', () async {
      bloc.add(const ProgramCreateRequested(name: 'ASDF'));
      final state = await _awaitLoaded(
        bloc,
        (s) => s.lastCreatedProgramId != null,
      );

      expect(state.lastCreatedProgramId, equals(repo.programs.single.id));
      expect(state.programs.single.name, equals('ASDF'));
    });

    test('a single request never creates more than one program', () async {
      bloc.add(const ProgramCreateRequested(name: 'ASDF'));
      await _awaitLoaded(bloc, (s) => s.programs.isNotEmpty);

      expect(repo.createProgramCalls, hasLength(1));
      expect(
        repo.programs.where((p) => p.name == 'A' || p.name == 'AS'),
        isEmpty,
      );
    });

    test('does not create a program for an empty name', () async {
      bloc.add(const ProgramCreateRequested(name: ''));
      // The invalid create returns synchronously without emitting; drain the
      // bloc deterministically by awaiting a sentinel load that DOES emit.
      bloc.add(const ProgramListRequested());
      await _awaitLoaded(bloc, (_) => true);

      expect(repo.createProgramCalls, isEmpty);
      expect(repo.programs, isEmpty);
    });

    test('does not create a program for a whitespace-only name', () async {
      bloc.add(const ProgramCreateRequested(name: '   '));
      bloc.add(const ProgramListRequested());
      await _awaitLoaded(bloc, (_) => true);

      expect(repo.createProgramCalls, isEmpty);
      expect(repo.programs, isEmpty);
    });

    test('trims the name before creating', () async {
      bloc.add(const ProgramCreateRequested(name: '  Push Pull Legs  '));
      await _awaitLoaded(bloc, (s) => s.programs.isNotEmpty);

      expect(repo.programs.single.name, equals('Push Pull Legs'));
    });

    test('navigation signal is one-shot — cleared once handled', () async {
      bloc.add(const ProgramCreateRequested(name: 'ASDF'));
      await _awaitLoaded(bloc, (s) => s.lastCreatedProgramId != null);

      bloc.add(const ProgramCreateNavigationHandled());
      final cleared = await _awaitLoaded(
        bloc,
        (s) => s.lastCreatedProgramId == null,
      );

      expect(cleared.lastCreatedProgramId, isNull);
      // The program itself is untouched by clearing the navigation signal.
      expect(cleared.programs.single.name, equals('ASDF'));
    });
  });

  group('ProgramNameRules.canCreate', () {
    test('accepts a normal trimmed name', () {
      expect(ProgramNameRules.canCreate('ASDF'), isTrue);
    });

    test('rejects an empty name', () {
      expect(ProgramNameRules.canCreate(''), isFalse);
    });

    test('rejects a whitespace-only name', () {
      expect(ProgramNameRules.canCreate('   '), isFalse);
    });

    test('accepts a name at the 100-character limit', () {
      expect(ProgramNameRules.canCreate('a' * 100), isTrue);
    });

    test('rejects a name beyond the 100-character limit', () {
      expect(ProgramNameRules.canCreate('a' * 101), isFalse);
    });

    test('counts length on the trimmed value', () {
      // 100 non-space chars surrounded by spaces still fits.
      expect(ProgramNameRules.canCreate('  ${'a' * 100}  '), isTrue);
    });
  });
}
