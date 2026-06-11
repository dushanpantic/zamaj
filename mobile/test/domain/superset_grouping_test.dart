import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  final t = DateTime.utc(2025);

  SessionExercise ex(String id, int position, {String? tag}) => SessionExercise(
    id: id,
    sessionId: 's-1',
    position: position,
    plannedExerciseIdInSnapshot: 'planned-$id',
    state: const ExerciseState.unfinished(),
    executedSets: const [],
    supersetTag: tag,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );

  List<List<String>> idsOf(List<List<SessionExercise>> groups) => [
    for (final g in groups) [for (final e in g) e.id],
  ];

  group('groupBySupersetRun', () {
    test('a contiguous same-tag run is one group; null-tag are singletons', () {
      final groups = groupBySupersetRun([
        ex('a', 0),
        ex('b', 1, tag: 'x'),
        ex('c', 2, tag: 'x'),
        ex('d', 3),
      ]);
      expect(idsOf(groups), [
        ['a'],
        ['b', 'c'],
        ['d'],
      ]);
    });

    test('a lone tagged exercise forms a singleton group', () {
      final groups = groupBySupersetRun([ex('a', 0, tag: 'x'), ex('b', 1)]);
      expect(idsOf(groups), [
        ['a'],
        ['b'],
      ]);
    });

    test('same-tag exercises separated by another do not merge', () {
      final groups = groupBySupersetRun([
        ex('a', 0, tag: 'x'),
        ex('b', 1),
        ex('c', 2, tag: 'x'),
      ]);
      expect(idsOf(groups), [
        ['a'],
        ['b'],
        ['c'],
      ]);
    });

    test('groups by position regardless of input order', () {
      final groups = groupBySupersetRun([
        ex('c', 2, tag: 'x'),
        ex('a', 0),
        ex('b', 1, tag: 'x'),
      ]);
      expect(idsOf(groups), [
        ['a'],
        ['b', 'c'],
      ]);
    });
  });
}
