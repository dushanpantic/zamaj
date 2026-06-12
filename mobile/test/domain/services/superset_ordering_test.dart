import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/services/superset_ordering.dart';

void main() {
  group('SupersetOrdering.blockedOrderForCreate', () {
    test('pulls chosen members into a contiguous block at the earliest anchor, '
        'preserving non-member order', () {
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['a', 'b', 'c', 'd'],
        chosenIds: ['a', 'c'],
      );
      // Anchor is a's slot (index 0); b and d keep their relative order after.
      expect(order, ['a', 'c', 'b', 'd']);
    });

    test('anchors the block at the first chosen position when it is not the '
        'first overall', () {
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['a', 'b', 'c', 'd'],
        chosenIds: ['b', 'd'],
      );
      expect(order, ['a', 'b', 'd', 'c']);
    });

    test('keeps the chosen block in the provided order', () {
      final order = SupersetOrdering.blockedOrderForCreate(
        allIds: ['a', 'b', 'c', 'd'],
        chosenIds: ['c', 'a'],
      );
      // First chosen present in allIds is 'a' (index 0) → anchor 0.
      expect(order, ['c', 'a', 'b', 'd']);
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
}
