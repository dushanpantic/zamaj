import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('CapHistoryEntry', () {
    test('carries date, program, day name, set pairs, and the cap flag', () {
      final entry = CapHistoryEntry(
        date: DateTime.utc(2026, 3, 1),
        programId: 'prog-1',
        sourceWorkoutDayName: 'Push',
        plannedSets: [
          PlannedSetValues.repBased(
            weightKg: 80,
            repTarget: RepTarget.range(minReps: 10, maxReps: 12),
          ),
        ],
        actualSets: const [ActualSetValues.repBased(weightKg: 80, reps: 12)],
        isCapped: true,
      );

      expect(entry.date, DateTime.utc(2026, 3, 1));
      expect(entry.programId, 'prog-1');
      expect(entry.sourceWorkoutDayName, 'Push');
      expect(entry.plannedSets, hasLength(1));
      expect(entry.actualSets, hasLength(1));
      expect(entry.isCapped, isTrue);
    });
  });

  group('CapHistory', () {
    test('empty history reports isEmpty', () {
      const history = CapHistory(entries: []);
      expect(history.isEmpty, isTrue);
    });

    test('non-empty history reports not isEmpty', () {
      final history = CapHistory(
        entries: [
          CapHistoryEntry(
            date: DateTime.utc(2026, 3, 1),
            programId: 'p',
            sourceWorkoutDayName: 'd',
            plannedSets: const [],
            actualSets: const [],
            isCapped: false,
          ),
        ],
      );
      expect(history.isEmpty, isFalse);
    });
  });
}
