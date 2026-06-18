// Validates the pure whole-superset reorder resolver: dragging a fully-
// unfinished superset into a between-group gap permutes only the unfinished
// id sequence (finished anchors keep their slots), guards stale/ineligible
// inputs to a no-op, and exposes a unit-tested whole-drag eligibility predicate.

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/superset_reorder_resolver.dart';

import 'whole_superset_reorder_fixture.dart';

void main() {
  group('SupersetReorderResolver.resolve', () {
    test('moves the whole superset down past a standalone group', () {
      // p · [x,y] · q  →  drop [x,y] into the gap below q  →  p · q · [x,y]
      final intent = SupersetReorderResolver.resolve(
        sessionId: supersetSessionId,
        groups: backgroundPxyQ(),
        supersetTag: supersetXyTag,
        targetUnfinishedIndex: gapBelowQ,
      );
      expect(
        intent,
        const DropIntent.reorder(
          sessionId: supersetSessionId,
          orderedUnfinishedIds: ['p', 'q', 'x', 'y'],
        ),
      );
    });

    test('moves the whole superset up past a standalone group', () {
      // drop [x,y] into the gap above p  →  [x,y] · p · q
      final intent = SupersetReorderResolver.resolve(
        sessionId: supersetSessionId,
        groups: backgroundPxyQ(),
        supersetTag: supersetXyTag,
        targetUnfinishedIndex: 0,
      );
      expect(
        intent,
        const DropIntent.reorder(
          sessionId: supersetSessionId,
          orderedUnfinishedIds: ['x', 'y', 'p', 'q'],
        ),
      );
    });

    test('a drop into the gap immediately above itself is a no-op', () {
      final intent = SupersetReorderResolver.resolve(
        sessionId: supersetSessionId,
        groups: backgroundPxyQ(),
        supersetTag: supersetXyTag,
        targetUnfinishedIndex: 1, // before x — where [x,y] already sits
      );
      expect(intent, const DropIntent.noop());
    });

    test('a drop into the gap immediately below itself is a no-op', () {
      final intent = SupersetReorderResolver.resolve(
        sessionId: supersetSessionId,
        groups: backgroundPxyQ(),
        supersetTag: supersetXyTag,
        targetUnfinishedIndex: 3, // after y, before q
      );
      expect(intent, const DropIntent.noop());
    });

    test(
      'finished exercises keep their slots; only unfinished ids permute',
      () {
        // p · F(finished) · [x,y] · q  →  drop [x,y] below q.
        // The unfinished sequence is [p, x, y, q]; F is not part of it.
        final groups = buildGroups([
          unfinished('p'),
          finished('F'),
          unfinished('x', tag: supersetXyTag),
          unfinished('y', tag: supersetXyTag),
          unfinished('q'),
        ]);
        final intent = SupersetReorderResolver.resolve(
          sessionId: supersetSessionId,
          groups: groups,
          supersetTag: supersetXyTag,
          targetUnfinishedIndex: gapBelowQ,
        );
        expect(
          intent,
          const DropIntent.reorder(
            sessionId: supersetSessionId,
            orderedUnfinishedIds: ['p', 'q', 'x', 'y'],
          ),
        );
      },
    );

    test('a group that is not fully unfinished resolves to a no-op', () {
      final groups = buildGroups([
        unfinished('p'),
        unfinished('x', tag: supersetXyTag),
        finished('y', tag: supersetXyTag),
        unfinished('q'),
      ]);
      final intent = SupersetReorderResolver.resolve(
        sessionId: supersetSessionId,
        groups: groups,
        supersetTag: supersetXyTag,
        targetUnfinishedIndex: gapBelowQ,
      );
      expect(intent, const DropIntent.noop());
    });

    test('an unknown or stale tag resolves to a no-op', () {
      final intent = SupersetReorderResolver.resolve(
        sessionId: supersetSessionId,
        groups: backgroundPxyQ(),
        supersetTag: 'gone',
        targetUnfinishedIndex: gapBelowQ,
      );
      expect(intent, const DropIntent.noop());
    });
  });

  group('SupersetReorderResolver.isWholeDragEligible', () {
    test('a fully-unfinished superset in a live session is eligible', () {
      expect(
        SupersetReorderResolver.isWholeDragEligible(
          groups: backgroundPxyQ(),
          supersetTag: supersetXyTag,
          isEnded: false,
        ),
        isTrue,
      );
    });

    test('a superset with any finished member is not eligible', () {
      final groups = buildGroups([
        unfinished('x', tag: supersetXyTag),
        finished('y', tag: supersetXyTag),
      ]);
      expect(
        SupersetReorderResolver.isWholeDragEligible(
          groups: groups,
          supersetTag: supersetXyTag,
          isEnded: false,
        ),
        isFalse,
      );
    });

    test('an ended session is not eligible', () {
      expect(
        SupersetReorderResolver.isWholeDragEligible(
          groups: backgroundPxyQ(),
          supersetTag: supersetXyTag,
          isEnded: true,
        ),
        isFalse,
      );
    });

    test('an unknown tag is not eligible', () {
      expect(
        SupersetReorderResolver.isWholeDragEligible(
          groups: backgroundPxyQ(),
          supersetTag: 'gone',
          isEnded: false,
        ),
        isFalse,
      );
    });
  });
}
