import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('LinkSuggester', () {
    const suggester = LinkSuggester();

    test('returns empty list when every exercise is already linked', () {
      final programs = [
        _program(
          id: 'p1',
          name: 'Push/Pull',
          days: [
            _day(
              id: 'd1',
              programId: 'p1',
              name: 'PUSH',
              groups: [
                _singleGroup(
                  id: 'g1',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e1',
                    groupId: 'g1',
                    name: 'BB Bench Press',
                    measurementType: const MeasurementType.repBased(),
                    libraryExerciseId: '00000000-0000-0000-0000-00000000000a',
                  ),
                ),
              ],
            ),
          ],
        ),
      ];

      expect(suggester.suggest(programs), isEmpty);
    });

    test(
      'groups unlinked exercises across programs by normalized name + type',
      () {
        final programs = [
          _program(
            id: 'p1',
            name: 'PPL',
            days: [
              _day(
                id: 'd1',
                programId: 'p1',
                name: 'PUSH',
                groups: [
                  _singleGroup(
                    id: 'g1',
                    dayId: 'd1',
                    exercise: _exercise(
                      id: 'e1',
                      groupId: 'g1',
                      name: 'BB Bench Press (long bar)',
                      measurementType: const MeasurementType.repBased(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _program(
            id: 'p2',
            name: 'Upper/Lower',
            days: [
              _day(
                id: 'd2',
                programId: 'p2',
                name: 'UPPER',
                groups: [
                  _singleGroup(
                    id: 'g2',
                    dayId: 'd2',
                    exercise: _exercise(
                      id: 'e2',
                      groupId: 'g2',
                      name: '  bb bench press (long bar)  ',
                      measurementType: const MeasurementType.repBased(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];

        final clusters = suggester.suggest(programs);

        expect(clusters, hasLength(1));
        final cluster = clusters.single;
        expect(cluster.normalizedName, 'bb bench press (long bar)');
        expect(cluster.suggestedName, 'BB Bench Press (long bar)');
        expect(cluster.measurementType, const MeasurementType.repBased());
        expect(cluster.occurrenceCount, 2);
        expect(cluster.occurrences.map((o) => o.programName).toSet(), {
          'PPL',
          'Upper/Lower',
        });
      },
    );

    test(
      'same name but different measurement type produces separate clusters',
      () {
        final programs = [
          _program(
            id: 'p1',
            name: 'P1',
            days: [
              _day(
                id: 'd1',
                programId: 'p1',
                name: 'D1',
                groups: [
                  _singleGroup(
                    id: 'g1',
                    dayId: 'd1',
                    exercise: _exercise(
                      id: 'e1',
                      groupId: 'g1',
                      name: 'Plank',
                      measurementType: const MeasurementType.timeBased(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          _program(
            id: 'p2',
            name: 'P2',
            days: [
              _day(
                id: 'd2',
                programId: 'p2',
                name: 'D2',
                groups: [
                  _singleGroup(
                    id: 'g2',
                    dayId: 'd2',
                    exercise: _exercise(
                      id: 'e2',
                      groupId: 'g2',
                      name: 'Plank',
                      measurementType: const MeasurementType.bodyweight(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];

        final clusters = suggester.suggest(programs);
        expect(clusters, hasLength(2));
      },
    );

    test('sorts clusters by occurrence count desc, then name asc', () {
      final programs = [
        _program(
          id: 'p1',
          name: 'PPL',
          days: [
            _day(
              id: 'd1',
              programId: 'p1',
              name: 'PUSH',
              groups: [
                _singleGroup(
                  id: 'g1',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e1',
                    groupId: 'g1',
                    name: 'Bench',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
                _singleGroup(
                  id: 'g2',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e2',
                    groupId: 'g2',
                    name: 'Apple',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
              ],
            ),
            _day(
              id: 'd2',
              programId: 'p1',
              name: 'UPPER',
              groups: [
                _singleGroup(
                  id: 'g3',
                  dayId: 'd2',
                  exercise: _exercise(
                    id: 'e3',
                    groupId: 'g3',
                    name: 'Bench',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ];

      final clusters = suggester.suggest(programs);
      expect(clusters.map((c) => c.suggestedName), ['Bench', 'Apple']);
    });

    test('suggestedVideoUrl picks the first non-null videoUrl seen', () {
      final programs = [
        _program(
          id: 'p1',
          name: 'P1',
          days: [
            _day(
              id: 'd1',
              programId: 'p1',
              name: 'D1',
              groups: [
                _singleGroup(
                  id: 'g1',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e1',
                    groupId: 'g1',
                    name: 'Squat',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
                _singleGroup(
                  id: 'g2',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e2',
                    groupId: 'g2',
                    name: 'Squat',
                    measurementType: const MeasurementType.repBased(),
                    videoUrl: 'https://example.com/squat.mp4',
                  ),
                ),
              ],
            ),
          ],
        ),
      ];

      final clusters = suggester.suggest(programs);
      expect(
        clusters.single.suggestedVideoUrl,
        'https://example.com/squat.mp4',
      );
    });

    test('chooses the longest variant as suggested name', () {
      final programs = [
        _program(
          id: 'p1',
          name: 'P1',
          days: [
            _day(
              id: 'd1',
              programId: 'p1',
              name: 'D1',
              groups: [
                _singleGroup(
                  id: 'g1',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e1',
                    groupId: 'g1',
                    name: 'OHP',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
                _singleGroup(
                  id: 'g2',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e2',
                    groupId: 'g2',
                    name: 'ohp',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ];

      final clusters = suggester.suggest(programs);
      // Both have the same length; first inserted wins, which is 'OHP'.
      expect(clusters.single.suggestedName, 'OHP');
    });

    test('ignores exercises with empty / whitespace-only names', () {
      final programs = [
        _program(
          id: 'p1',
          name: 'P1',
          days: [
            _day(
              id: 'd1',
              programId: 'p1',
              name: 'D1',
              groups: [
                _singleGroup(
                  id: 'g1',
                  dayId: 'd1',
                  exercise: _exercise(
                    id: 'e1',
                    groupId: 'g1',
                    name: '   ',
                    measurementType: const MeasurementType.repBased(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ];

      expect(suggester.suggest(programs), isEmpty);
    });
  });
}

ProgramAggregate _program({
  required String id,
  required String name,
  required List<WorkoutDayAggregate> days,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return ProgramAggregate(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 8,
    workoutDays: days,
  );
}

WorkoutDayAggregate _day({
  required String id,
  required String programId,
  required String name,
  required List<ExerciseGroupAggregate> groups,
}) {
  return WorkoutDayAggregate(
    id: id,
    programId: programId,
    name: name,
    position: 0,
    groups: groups,
  );
}

ExerciseGroupAggregate _singleGroup({
  required String id,
  required String dayId,
  required ExerciseAggregate exercise,
}) {
  return ExerciseGroupAggregate(
    id: id,
    workoutDayId: dayId,
    kind: const ExerciseGroupKind.single(),
    position: 0,
    exercises: [exercise],
  );
}

ExerciseAggregate _exercise({
  required String id,
  required String groupId,
  required String name,
  required MeasurementType measurementType,
  String? libraryExerciseId,
  String? videoUrl,
}) {
  return ExerciseAggregate(
    id: id,
    groupId: groupId,
    name: name,
    measurementType: measurementType,
    metadata: ExerciseMetadata(videoUrl: videoUrl),
    plannedRestSeconds: null,
    libraryExerciseId: libraryExerciseId,
    position: 0,
    sets: const [],
  );
}
