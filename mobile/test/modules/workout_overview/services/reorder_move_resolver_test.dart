// Validates the tap-only Move up/down fallback: the DropTargets computed by
// ReorderMoveResolver, when run through the existing DropResolver reorder
// path, produce the expected unfinished ordering — including the sequence
// ends, finished anchors, superset-jumping for standalones, and within-group
// scoping for superset members.

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drop_resolver.dart';
import 'package:zamaj/modules/workout_overview/services/reorder_move_resolver.dart';

const _sessionId = 'session-1';

void main() {
  group('ReorderMoveResolver — standalone exercises', () {
    test('middle exercise moves up and down by one', () {
      final specs = [
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
        _spec('c', state: const ExerciseState.unfinished()),
      ];
      expect(_movedOrder(specs, 'b', up: true), ['b', 'a', 'c']);
      expect(_movedOrder(specs, 'b', up: false), ['a', 'c', 'b']);
    });

    test('ends are disabled (no-op direction returns null)', () {
      final specs = [
        _spec('a', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished()),
        _spec('c', state: const ExerciseState.unfinished()),
      ];
      expect(_targets(specs, 'a').up, isNull);
      expect(_targets(specs, 'c').down, isNull);
    });

    test('finished exercises are skipped anchors', () {
      // a is done; b is already first in the unfinished sequence, so it can't
      // move up past the anchor — but it can swap down with c.
      final specs = [
        _spec('a', state: const ExerciseState.completed()),
        _spec('b', state: const ExerciseState.unfinished()),
        _spec('c', state: const ExerciseState.unfinished()),
      ];
      expect(_targets(specs, 'b').up, isNull);
      expect(_movedOrder(specs, 'b', up: false), ['c', 'b']);
    });

    test('moving down jumps over an entire superset, keeping it intact', () {
      final specs = [
        _spec('d', state: const ExerciseState.unfinished()),
        _spec('b', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        _spec('c', state: const ExerciseState.unfinished(), supersetTag: 'x'),
      ];
      // d lands after the whole [b, c] group, not between its members.
      expect(_movedOrder(specs, 'd', up: false), ['b', 'c', 'd']);
    });

    test('moving up jumps over an entire superset above', () {
      final specs = [
        _spec('b', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        _spec('c', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        _spec('d', state: const ExerciseState.unfinished()),
      ];
      expect(_movedOrder(specs, 'd', up: true), ['d', 'b', 'c']);
    });

    test('a lone unfinished exercise has no move targets', () {
      final specs = [
        _spec('a', state: const ExerciseState.completed()),
        _spec('b', state: const ExerciseState.unfinished()),
      ];
      final targets = _targets(specs, 'b');
      expect(targets.up, isNull);
      expect(targets.down, isNull);
      expect(targets.hasAny, isFalse);
    });

    test('finished exercises have no move targets', () {
      final specs = [
        _spec('a', state: const ExerciseState.completed()),
        _spec('b', state: const ExerciseState.unfinished()),
      ];
      expect(_targets(specs, 'a').hasAny, isFalse);
    });
  });

  group('ReorderMoveResolver — superset members', () {
    test('members swap within their group', () {
      final specs = [
        _spec('b', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        _spec('c', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        _spec('d', state: const ExerciseState.unfinished(), supersetTag: 'x'),
      ];
      expect(_movedOrder(specs, 'b', up: false), ['c', 'b', 'd']);
      expect(_movedOrder(specs, 'c', up: true), ['c', 'b', 'd']);
      expect(_movedOrder(specs, 'd', up: true), ['b', 'd', 'c']);
    });

    test('group ends are disabled so a member never escapes its group', () {
      final specs = [
        _spec('b', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        _spec('c', state: const ExerciseState.unfinished(), supersetTag: 'x'),
        // A following standalone the last member must NOT be able to move into.
        _spec('e', state: const ExerciseState.unfinished()),
      ];
      expect(_targets(specs, 'b').up, isNull);
      expect(_targets(specs, 'c').down, isNull);
      // The first member can still move down within the group.
      expect(_movedOrder(specs, 'b', up: false), ['c', 'b', 'e']);
    });
  });
}

/// Resolves [id]'s move target for the given direction, runs it through the
/// production [DropResolver] reorder path, and returns the resulting unfinished
/// ordering — or null when the direction is disabled (a no-op end).
List<String>? _movedOrder(List<_Spec> specs, String id, {required bool up}) {
  final groups = _groups(specs);
  final targets = ReorderMoveResolver.targetsFor(
    groups: groups,
    sessionExerciseId: id,
  );
  final target = up ? targets.up : targets.down;
  if (target == null) return null;
  final intent = DropResolver.resolve(
    sessionId: _sessionId,
    groups: groups,
    draggedSessionExerciseId: id,
    target: target,
  );
  return switch (intent) {
    ReorderIntent(:final orderedUnfinishedIds) => orderedUnfinishedIds,
    _ => throw StateError('expected ReorderIntent, got $intent'),
  };
}

MoveTargets _targets(List<_Spec> specs, String id) =>
    ReorderMoveResolver.targetsFor(
      groups: _groups(specs),
      sessionExerciseId: id,
    );

class _Spec {
  _Spec({required this.id, required this.state, required this.supersetTag});
  final String id;
  final ExerciseState state;
  final String? supersetTag;
}

_Spec _spec(String id, {required ExerciseState state, String? supersetTag}) =>
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
      plannedExerciseName: planned.name,
      plannedSummary: '0 sets',
      plannedMeasurementType: planned.measurementType,
      plannedMetadata: planned.metadata,
      plannedRestSeconds: null,
      setRows: const <SetRowViewModel>[],
      isLoggable: false,
      effectiveMeasurementType: const MeasurementType.repBased(),
    );
  }

  final out = <SupersetGroupViewModel>[];
  var i = 0;
  while (i < specs.length) {
    final s = specs[i];
    final vm = viewModel(s, i);
    if (s.supersetTag == null) {
      out.add(SupersetGroupViewModel.single(exercise: vm));
      i++;
      continue;
    }
    final tag = s.supersetTag!;
    final group = <ExerciseViewModel>[vm];
    var j = i + 1;
    while (j < specs.length && specs[j].supersetTag == tag) {
      group.add(viewModel(specs[j], j));
      j++;
    }
    if (group.length == 1) {
      out.add(SupersetGroupViewModel.single(exercise: group.single));
    } else {
      out.add(SupersetGroupViewModel.superset(tag: tag, exercises: group));
    }
    i = j;
  }
  return out;
}
