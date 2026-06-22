import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/services/superset_ordering.dart';

void main() {
  group('SupersetOrdering.blockedOrderForCreate', () {
    test('anchors the block at the drop-target slot, ordered as chosen', () {
      // Drag "A" onto target "B" within "A, X, Y, B": the new [A, B] group
      // lands at B's slot, below the existing [X, Y].
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['A', 'X', 'Y', 'B'],
        chosenIds: ['A', 'B'],
        anchorId: 'B',
      );
      expect(order, ['X', 'Y', 'A', 'B']);
    });

    test('anchors at the target even when the target is the earliest slot', () {
      // Drag "B" onto target "A": the new [B, A] group lands at A's slot.
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['A', 'X', 'Y', 'B'],
        chosenIds: ['B', 'A'],
        anchorId: 'A',
      );
      expect(order, ['B', 'A', 'X', 'Y']);
    });

    test('pulls non-adjacent members into one block at the target, '
        'preserving non-member order', () {
      // Drag "a" onto target "c": block lands at c's slot; b and d keep order.
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['a', 'b', 'c', 'd'],
        chosenIds: ['a', 'c'],
        anchorId: 'c',
      );
      expect(order, ['b', 'a', 'c', 'd']);
    });

    test('grouping two already-adjacent exercises keeps the global order', () {
      // Drag "b" onto target "c": already adjacent, so nothing moves.
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['a', 'b', 'c', 'd'],
        chosenIds: ['b', 'c'],
        anchorId: 'c',
      );
      expect(order, ['a', 'b', 'c', 'd']);
    });

    test('a terminal exercise in range keeps its absolute slot', () {
      // "F" is skipped (a non-member); "A","B" group below it at B's slot.
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['F', 'A', 'B'],
        chosenIds: ['A', 'B'],
        anchorId: 'B',
      );
      expect(order, ['F', 'A', 'B']);
    });

    test('throws when the anchor is not one of the chosen members', () {
      expect(
        () => SupersetOrdering.blockedOrderForCreate(
          allIds: ['a', 'b', 'c'],
          chosenIds: ['a', 'b'],
          anchorId: 'c',
        ),
        throwsArgumentError,
      );
    });
  });

  group('SupersetOrdering.orderForAppend', () {
    test(
      'inserts the dragged id immediately after the last existing member',
      () {
        final order = SupersetOrdering.orderForAppend(
          unfinishedIds: ['a', 'b', 'c', 'd'],
          memberIds: ['a', 'b'],
          draggedId: 'd',
        );
        expect(order, ['a', 'b', 'd', 'c']);
      },
    );

    test(
      'moves a dragged id that sits before the members to just after them',
      () {
        final order = SupersetOrdering.orderForAppend(
          unfinishedIds: ['x', 'a', 'b', 'c'],
          memberIds: ['a', 'b'],
          draggedId: 'x',
        );
        expect(order, ['a', 'b', 'x', 'c']);
      },
    );
  });

  group('SupersetOrdering.orderForExtract', () {
    // Background mirrors the Slice 1 Gherkin: order
    // "Squat, [Bench, Row, Curl], Plank" with all five unfinished.
    const all = ['Squat', 'Bench', 'Row', 'Curl', 'Plank'];
    const members = ['Bench', 'Row', 'Curl'];

    test('extracting the middle member places it right under the group', () {
      final order = SupersetOrdering.orderForExtract(
        unfinishedIds: all,
        memberIds: members,
        extractedId: 'Row',
      );
      // Remaining group [Bench, Curl] stays contiguous; Row drops just below.
      expect(order, ['Squat', 'Bench', 'Curl', 'Row', 'Plank']);
    });

    test('extracting the first member places it right under the group', () {
      final order = SupersetOrdering.orderForExtract(
        unfinishedIds: all,
        memberIds: members,
        extractedId: 'Bench',
      );
      expect(order, ['Squat', 'Row', 'Curl', 'Bench', 'Plank']);
    });

    test('extracting the last member leaves it in place under the group', () {
      final order = SupersetOrdering.orderForExtract(
        unfinishedIds: all,
        memberIds: members,
        extractedId: 'Curl',
      );
      expect(order, ['Squat', 'Bench', 'Row', 'Curl', 'Plank']);
    });

    test('non-members keep their relative order', () {
      final order = SupersetOrdering.orderForExtract(
        unfinishedIds: all,
        memberIds: members,
        extractedId: 'Row',
      );
      final nonMembers = order
          .where((id) => id == 'Squat' || id == 'Plank')
          .toList();
      expect(nonMembers, ['Squat', 'Plank']);
    });

    test('output is exactly a permutation of the unfinished input — the '
        'function never sees finished ids, so the caller splices them back at '
        'their absolute slots', () {
      final order = SupersetOrdering.orderForExtract(
        unfinishedIds: all,
        memberIds: members,
        extractedId: 'Bench',
      );
      expect(order.toSet(), all.toSet());
      expect(order.length, all.length);
    });
  });
}
