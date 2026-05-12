// Validates: Requirements R4, R5 AC1–AC4

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drop_resolver.dart';

const _sessionId = 'session-1';

void main() {
  group('DropResolver.resolve', () {
    test('drop outside → noop', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.outside(),
      );
      expect(intent, isA<NoopIntent>());
    });

    test('drop on self → noop', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.ontoExercise('a'),
      );
      expect(intent, isA<NoopIntent>());
    });

    test('drop on locked → noop', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.completed()),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.ontoExercise('b'),
      );
      expect(intent, isA<NoopIntent>());
    });

    test('drop into same gap → noop', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
      ]);
      final intent0 = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.beforeIndex(0),
      );
      final intent1 = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.beforeIndex(1),
      );
      expect(intent0, isA<NoopIntent>());
      expect(intent1, isA<NoopIntent>());
    });

    test('drop into different gap → reorder with permuted ids', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
        _spec('c', state: const ExerciseState.unfinished()),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.beforeIndex(2),
      );
      expect(
        intent,
        const DropIntent.reorder(
          sessionId: _sessionId,
          orderedUnfinishedIds: ['b', 'a', 'c'],
        ),
      );
    });

    test('drop on unfinished outside any superset → createSuperset '
        'with [draggedId, targetId]', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.ontoExercise('b'),
      );
      expect(
        intent,
        const DropIntent.createSuperset(
          sessionId: _sessionId,
          sessionExerciseIds: ['a', 'b'],
        ),
      );
    });

    test('drop within same superset → noop', () {
      final groups = _groups([
        _spec(
          'a',
          state: const ExerciseState.unfinished(),
          supersetTag: 'tag-x',
        ),
        _spec(
          'b',
          state: const ExerciseState.unfinished(),
          supersetTag: 'tag-x',
        ),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.ontoExercise('b'),
      );
      expect(intent, isA<NoopIntent>());
    });

    test('drop across supersets → noop', () {
      final groups = _groups([
        _spec(
          'a',
          state: const ExerciseState.unfinished(),
          supersetTag: 'tag-x',
        ),
        _spec(
          'b',
          state: const ExerciseState.unfinished(),
          supersetTag: 'tag-x',
        ),
        _spec(
          'c',
          state: const ExerciseState.unfinished(),
          supersetTag: 'tag-y',
        ),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.ontoExercise('c'),
      );
      expect(intent, isA<NoopIntent>());
    });

    test('dragged not in unfinished list → noop', () {
      final groups = _groups([
        _spec('a', state: const ExerciseState.completed()),
        _spec('b', state: const ExerciseState.unfinished()),
      ]);
      final intent = DropResolver.resolve(
        sessionId: _sessionId,
        groups: groups,
        draggedSessionExerciseId: 'a',
        target: const DropTarget.ontoExercise('b'),
      );
      expect(intent, isA<NoopIntent>());
    });
  });
}

class _Spec {
  _Spec({required this.id, required this.state, required this.supersetTag});
  final String id;
  final ExerciseState state;
  final String? supersetTag;
}

_Spec _spec(
  String id, {
  required ExerciseState state,
  String? supersetTag,
}) =>
    _Spec(id: id, state: state, supersetTag: supersetTag);

List<SupersetGroupViewModel> _groups(List<_Spec> specs) {
  final now = DateTime.utc(2025);
  ExerciseViewModel viewModel(_Spec s, int position) {
    final ex = SessionExercise(
      id: s.id,
      sessionId: _sessionId,
      position: position,
      plannedExerciseIdInSnapshot: 'planned-${s.id}',
      state: s.state,
      executedSets: const [],
      supersetTag: s.supersetTag,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
    final planned = Exercise(
      id: 'planned-${s.id}',
      exerciseGroupId: 'g-${s.id}',
      position: 0,
      name: s.id,
      measurementType: const MeasurementType.repBased(),
      metadata: const ExerciseMetadata(),
      sets: const [],
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
    return ExerciseViewModel(
      sessionExercise: ex,
      plannedExerciseInSnapshot: planned,
      plannedSummary: '0 sets',
      setRows: const <SetRowViewModel>[],
      isCursorTarget: false,
      cursorSetIndex: null,
      effectiveMeasurementType: const MeasurementType.repBased(),
    );
  }

  final out = <SupersetGroupViewModel>[];
  String? currentTag;
  var hasCurrent = false;
  final buffer = <ExerciseViewModel>[];

  void flush() {
    if (buffer.isEmpty) return;
    if (currentTag == null) {
      for (final vm in buffer) {
        out.add(SupersetGroupViewModel(supersetTag: null, exercises: [vm]));
      }
    } else {
      out.add(
        SupersetGroupViewModel(
          supersetTag: currentTag,
          exercises: List<ExerciseViewModel>.of(buffer),
        ),
      );
    }
    buffer.clear();
  }

  for (var i = 0; i < specs.length; i++) {
    final s = specs[i];
    final vm = viewModel(s, i);
    final tagMatches =
        hasCurrent && s.supersetTag != null && s.supersetTag == currentTag;
    if (tagMatches) {
      buffer.add(vm);
    } else {
      flush();
      currentTag = s.supersetTag;
      hasCurrent = true;
      buffer.add(vm);
    }
  }
  flush();
  return out;
}
