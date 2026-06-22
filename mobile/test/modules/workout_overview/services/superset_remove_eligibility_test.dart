import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/superset_remove_eligibility.dart';

import 'whole_superset_reorder_fixture.dart';

SupersetGroupViewModel _onlyGroup(List<ExSpec> specs) =>
    buildGroups(specs).single;

void main() {
  group('SupersetRemoveEligibility.canRemove (the gating rule)', () {
    test('true only when live, fully unfinished, and 3+ members', () {
      expect(
        SupersetRemoveEligibility.canRemove(
          memberCount: 3,
          allUnfinished: true,
          canMutate: true,
        ),
        isTrue,
      );
    });

    test('false on a 2-member group (Ungroup is the leave action there)', () {
      expect(
        SupersetRemoveEligibility.canRemove(
          memberCount: 2,
          allUnfinished: true,
          canMutate: true,
        ),
        isFalse,
      );
    });

    test('false when any member is finished (fixed anchor)', () {
      expect(
        SupersetRemoveEligibility.canRemove(
          memberCount: 3,
          allUnfinished: false,
          canMutate: true,
        ),
        isFalse,
      );
    });

    test('false once the session can no longer mutate (ended)', () {
      expect(
        SupersetRemoveEligibility.canRemove(
          memberCount: 3,
          allUnfinished: true,
          canMutate: false,
        ),
        isFalse,
      );
    });
  });

  group('SupersetRemoveEligibility.canRemoveFromGroup', () {
    test('true for a live, fully-unfinished 3-member superset', () {
      final group = _onlyGroup([
        unfinished('a', tag: 't'),
        unfinished('b', tag: 't'),
        unfinished('c', tag: 't'),
      ]);
      expect(
        SupersetRemoveEligibility.canRemoveFromGroup(group, canMutate: true),
        isTrue,
      );
    });

    test('false for a 2-member superset', () {
      final group = _onlyGroup([
        unfinished('a', tag: 't'),
        unfinished('b', tag: 't'),
      ]);
      expect(
        SupersetRemoveEligibility.canRemoveFromGroup(group, canMutate: true),
        isFalse,
      );
    });

    test('false for a partially-finished superset', () {
      final group = _onlyGroup([
        unfinished('a', tag: 't'),
        finished('b', tag: 't'),
        unfinished('c', tag: 't'),
      ]);
      expect(
        SupersetRemoveEligibility.canRemoveFromGroup(group, canMutate: true),
        isFalse,
      );
    });

    test('false for a standalone exercise', () {
      final group = _onlyGroup([unfinished('a')]);
      expect(
        SupersetRemoveEligibility.canRemoveFromGroup(group, canMutate: true),
        isFalse,
      );
    });

    test('false once the session has ended (canMutate false)', () {
      final group = _onlyGroup([
        unfinished('a', tag: 't'),
        unfinished('b', tag: 't'),
        unfinished('c', tag: 't'),
      ]);
      expect(
        SupersetRemoveEligibility.canRemoveFromGroup(group, canMutate: false),
        isFalse,
      );
    });
  });
}
