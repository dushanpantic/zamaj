// TEMP: snapshot link repair — remove after one-time run
//
// Unit coverage for the pure matching/rewrite planner. Drives
// [SnapshotLinkBackfill.plan] against current-template days plus historical
// ended sessions and asserts the rewrite set + report counts.

import 'package:flutter_test/flutter_test.dart';
// Imported via the barrel to assert the temporary service is exported there.
import 'package:zamaj/modules/domain/domain.dart';

final _t = DateTime.utc(2024);

const _libA = '11111111-1111-4111-8111-111111111111';
const _libB = '22222222-2222-4222-8222-222222222222';
const _libStale = '99999999-9999-4999-8999-999999999999';

Exercise _ex({
  required String id,
  required String name,
  String? libraryExerciseId,
  int position = 0,
  String groupId = 'g',
}) => Exercise(
  id: id,
  exerciseGroupId: groupId,
  position: position,
  name: name,
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  libraryExerciseId: libraryExerciseId,
  sets: const [],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

ExerciseGroup _group({
  required String id,
  required List<Exercise> exercises,
  String workoutDayId = 'wd1',
  int position = 0,
  ExerciseGroupKind kind = const ExerciseGroupKind.single(),
}) => ExerciseGroup(
  id: id,
  workoutDayId: workoutDayId,
  position: position,
  kind: kind,
  exercises: exercises,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

WorkoutDay _day({
  String id = 'wd1',
  required List<ExerciseGroup> groups,
  String programId = 'prog',
  String name = 'Day',
}) => WorkoutDay(
  id: id,
  programId: programId,
  name: name,
  exerciseGroups: groups,
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

Session _endedSession({required String id, required WorkoutDay snapshotDay}) {
  final snapshot = SessionSnapshot.capture(
    workoutDay: snapshotDay,
    capturedAt: _t,
    schemaVersion: 1,
  );
  return Session(
    id: id,
    workoutDayId: snapshotDay.id,
    snapshot: snapshot,
    sessionExercises: const [],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    endedAt: _t,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

/// The single exercise of the (single-group) rewritten day for [rewrite].
Exercise _onlyExerciseOf(SnapshotLinkRewrite rewrite) =>
    rewrite.workoutDay.exerciseGroups.single.exercises.single;

void main() {
  group('SnapshotLinkBackfill.plan', () {
    test('re-links a snapshot exercise still present by id (E1)', () {
      final current = _day(
        groups: [
          _group(
            id: 'g1',
            exercises: [
              _ex(id: 'ex-bench', name: 'Bench', libraryExerciseId: _libA),
            ],
          ),
        ],
      );
      final session = _endedSession(
        id: 's1',
        snapshotDay: _day(
          groups: [
            _group(
              id: 'g1',
              exercises: [
                _ex(
                  id: 'ex-bench',
                  name: 'Bench',
                  libraryExerciseId: _libStale,
                ),
              ],
            ),
          ],
        ),
      );

      final plan = SnapshotLinkBackfill.plan(
        currentDays: [current],
        sessions: [session],
      );

      expect(plan.sessionsScanned, 1);
      expect(plan.exercisesReLinked, 1);
      expect(plan.rewrites, hasLength(1));
      final rewrite = plan.rewrites.single;
      expect(rewrite.sessionId, 's1');
      expect(_onlyExerciseOf(rewrite).libraryExerciseId, _libA);
    });

    test('re-links a null-linked snapshot exercise by id (E1)', () {
      final current = _day(
        groups: [
          _group(
            id: 'g1',
            exercises: [
              _ex(id: 'ex-bench', name: 'Bench', libraryExerciseId: _libA),
            ],
          ),
        ],
      );
      final session = _endedSession(
        id: 's1',
        snapshotDay: _day(
          groups: [
            _group(
              id: 'g1',
              exercises: [_ex(id: 'ex-bench', name: 'Bench')],
            ),
          ],
        ),
      );

      final plan = SnapshotLinkBackfill.plan(
        currentDays: [current],
        sessions: [session],
      );

      expect(plan.exercisesReLinked, 1);
      expect(_onlyExerciseOf(plan.rewrites.single).libraryExerciseId, _libA);
    });

    test(
      'falls back to a unique normalized-name match when id is gone (E2)',
      () {
        final current = _day(
          groups: [
            _group(
              id: 'g1',
              exercises: [
                _ex(
                  id: 'ex-new',
                  name: 'Bench Press',
                  libraryExerciseId: _libA,
                ),
              ],
            ),
          ],
        );
        final session = _endedSession(
          id: 's1',
          snapshotDay: _day(
            groups: [
              _group(
                id: 'g1',
                exercises: [
                  _ex(
                    id: 'ex-old',
                    name: '  bench press ',
                    libraryExerciseId: _libStale,
                  ),
                ],
              ),
            ],
          ),
        );

        final plan = SnapshotLinkBackfill.plan(
          currentDays: [current],
          sessions: [session],
        );

        expect(plan.exercisesReLinked, 1);
        expect(_onlyExerciseOf(plan.rewrites.single).libraryExerciseId, _libA);
      },
    );

    test(
      'leaves an ambiguous name match unchanged and reports unmatched (E3)',
      () {
        final current = _day(
          groups: [
            _group(
              id: 'g-super',
              kind: const ExerciseGroupKind.superset(),
              exercises: [
                _ex(
                  id: 'ex-r1',
                  name: 'Row',
                  position: 0,
                  libraryExerciseId: _libA,
                ),
                _ex(
                  id: 'ex-r2',
                  name: 'Row',
                  position: 1,
                  libraryExerciseId: _libB,
                ),
              ],
            ),
          ],
        );
        final session = _endedSession(
          id: 's1',
          snapshotDay: _day(
            groups: [
              _group(
                id: 'g1',
                exercises: [
                  _ex(id: 'ex-old', name: 'row', libraryExerciseId: _libStale),
                ],
              ),
            ],
          ),
        );

        final plan = SnapshotLinkBackfill.plan(
          currentDays: [current],
          sessions: [session],
        );

        expect(plan.exercisesReLinked, 0);
        expect(plan.unmatched, 1);
        expect(plan.rewrites, isEmpty);
      },
    );

    test(
      'leaves an absent name match unchanged and reports unmatched (E3)',
      () {
        final current = _day(
          groups: [
            _group(
              id: 'g1',
              exercises: [
                _ex(id: 'ex-new', name: 'Bench', libraryExerciseId: _libA),
              ],
            ),
          ],
        );
        final session = _endedSession(
          id: 's1',
          snapshotDay: _day(
            groups: [
              _group(
                id: 'g1',
                exercises: [
                  _ex(
                    id: 'ex-old',
                    name: 'Squat',
                    libraryExerciseId: _libStale,
                  ),
                ],
              ),
            ],
          ),
        );

        final plan = SnapshotLinkBackfill.plan(
          currentDays: [current],
          sessions: [session],
        );

        expect(plan.exercisesReLinked, 0);
        expect(plan.unmatched, 1);
        expect(plan.rewrites, isEmpty);
      },
    );

    test(
      'never clears a link when the matched current exercise is unlinked (E4)',
      () {
        final current = _day(
          groups: [
            _group(
              id: 'g1',
              exercises: [_ex(id: 'ex-bench', name: 'Bench')],
            ),
          ],
        );
        final session = _endedSession(
          id: 's1',
          snapshotDay: _day(
            groups: [
              _group(
                id: 'g1',
                exercises: [
                  _ex(
                    id: 'ex-bench',
                    name: 'Bench',
                    libraryExerciseId: _libStale,
                  ),
                ],
              ),
            ],
          ),
        );

        final plan = SnapshotLinkBackfill.plan(
          currentDays: [current],
          sessions: [session],
        );

        expect(plan.exercisesReLinked, 0);
        expect(plan.currentUnlinked, 1);
        expect(plan.rewrites, isEmpty);
      },
    );

    test('produces no rewrite when the snapshot is already correct (E5)', () {
      final current = _day(
        groups: [
          _group(
            id: 'g1',
            exercises: [
              _ex(id: 'ex-bench', name: 'Bench', libraryExerciseId: _libA),
            ],
          ),
        ],
      );
      final session = _endedSession(
        id: 's1',
        snapshotDay: _day(
          groups: [
            _group(
              id: 'g1',
              exercises: [
                _ex(id: 'ex-bench', name: 'Bench', libraryExerciseId: _libA),
              ],
            ),
          ],
        ),
      );

      final plan = SnapshotLinkBackfill.plan(
        currentDays: [current],
        sessions: [session],
      );

      expect(plan.exercisesReLinked, 0);
      expect(plan.unmatched, 0);
      expect(plan.currentUnlinked, 0);
      expect(plan.rewrites, isEmpty);
    });

    test(
      'reports a session whose day was deleted without rewriting it (E6)',
      () {
        // The current template no longer contains the session's workout day.
        final session = _endedSession(
          id: 's1',
          snapshotDay: _day(
            id: 'wd-deleted',
            groups: [
              _group(
                id: 'g1',
                workoutDayId: 'wd-deleted',
                exercises: [
                  _ex(
                    id: 'ex-bench',
                    name: 'Bench',
                    libraryExerciseId: _libStale,
                  ),
                ],
              ),
            ],
          ),
        );

        final plan = SnapshotLinkBackfill.plan(
          currentDays: const [],
          sessions: [session],
        );

        expect(plan.sessionsScanned, 1);
        expect(plan.dayMissing, 1);
        expect(plan.exercisesReLinked, 0);
        expect(plan.rewrites, isEmpty);
      },
    );

    test('repairs every member of a superset group (E10)', () {
      final current = _day(
        groups: [
          _group(
            id: 'g-super',
            kind: const ExerciseGroupKind.superset(),
            exercises: [
              _ex(
                id: 'ex-r1',
                name: 'Row',
                position: 0,
                libraryExerciseId: _libA,
              ),
              _ex(
                id: 'ex-r2',
                name: 'Pulldown',
                position: 1,
                libraryExerciseId: _libB,
              ),
            ],
          ),
        ],
      );
      final session = _endedSession(
        id: 's1',
        snapshotDay: _day(
          groups: [
            _group(
              id: 'g-super',
              kind: const ExerciseGroupKind.superset(),
              exercises: [
                _ex(
                  id: 'ex-r1',
                  name: 'Row',
                  position: 0,
                  libraryExerciseId: _libStale,
                ),
                _ex(id: 'ex-r2', name: 'Pulldown', position: 1),
              ],
            ),
          ],
        ),
      );

      final plan = SnapshotLinkBackfill.plan(
        currentDays: [current],
        sessions: [session],
      );

      expect(plan.exercisesReLinked, 2);
      expect(plan.rewrites, hasLength(1));
      final group = plan.rewrites.single.workoutDay.exerciseGroups.single;
      expect(group.kind, const ExerciseGroupKind.superset());
      expect(group.exercises.map((e) => e.libraryExerciseId), [_libA, _libB]);
    });
  });
}
