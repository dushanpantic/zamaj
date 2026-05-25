import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/planned_draft_summary_formatter.dart';

void main() {
  group('PlannedDraftSummaryFormatter.summarize — rep-based', () {
    test('uniform single-rep sets render as "<kg>kg N×reps"', () {
      final exercise = _repExercise([
        _repSet(weight: '60', reps: '5'),
        _repSet(weight: '60', reps: '5'),
        _repSet(weight: '60', reps: '5'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '60kg 3×5');
    });

    test('uniform rep-range sets render as "<kg>kg N×min-max"', () {
      final exercise = _repExercise([
        _repSet(weight: '60', reps: '5-8'),
        _repSet(weight: '60', reps: '5-8'),
        _repSet(weight: '60', reps: '5-8'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '60kg 3×5-8');
    });

    test('en-dash range is equivalent to hyphen range', () {
      final exercise = _repExercise([
        _repSet(weight: '60', reps: '5-8'),
        _repSet(weight: '60', reps: '5 – 8'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '60kg 2×5-8');
    });

    test('mixed reps, same weight, ≤6 sets → list reps', () {
      final exercise = _repExercise([
        _repSet(weight: '60', reps: '5'),
        _repSet(weight: '60', reps: '5'),
        _repSet(weight: '60', reps: '8'),
        _repSet(weight: '60', reps: '8'),
      ]);
      expect(
        PlannedDraftSummaryFormatter.summarize(exercise),
        '60kg · 5/5/8/8',
      );
    });

    test('mixed reps, same weight, >6 sets → N sets', () {
      final exercise = _repExercise([
        for (var i = 0; i < 7; i++)
          _repSet(weight: '60', reps: i.isEven ? '5' : '6'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '60kg · 7 sets');
    });

    test('varying weight, same reps → "<lo>-<hi>kg N×reps"', () {
      final exercise = _repExercise([
        _repSet(weight: '60', reps: '5'),
        _repSet(weight: '70', reps: '5'),
        _repSet(weight: '80', reps: '5'),
        _repSet(weight: '80', reps: '5'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '60-80kg 4×5');
    });

    test('varying both → "N sets · <lo>-<hi>kg"', () {
      final exercise = _repExercise([
        _repSet(weight: '60', reps: '5'),
        _repSet(weight: '70', reps: '8'),
        _repSet(weight: '80', reps: '6'),
        _repSet(weight: '80', reps: '8'),
      ]);
      expect(
        PlannedDraftSummaryFormatter.summarize(exercise),
        '4 sets · 60-80kg',
      );
    });

    test('empty sets render "No sets planned"', () {
      final exercise = _repExercise(const []);
      expect(
        PlannedDraftSummaryFormatter.summarize(exercise),
        'No sets planned',
      );
      expect(PlannedDraftSummaryFormatter.isNoSetsPlanned(exercise), isTrue);
    });

    test('fractional weight keeps the decimal', () {
      final exercise = _repExercise([
        _repSet(weight: '97.5', reps: '5'),
        _repSet(weight: '97.5', reps: '5'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '97.5kg 2×5');
    });
  });

  group('PlannedDraftSummaryFormatter.summarize — bodyweight', () {
    test('uniform fixed reps render "BW · N×reps"', () {
      final exercise = _bwExercise([_bwSet('8'), _bwSet('8'), _bwSet('8')]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), 'BW · 3×8');
    });

    test('uniform rep-range renders "BW · N×min-max"', () {
      final exercise = _bwExercise([_bwSet('5-8'), _bwSet('5-8')]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), 'BW · 2×5-8');
    });

    test('mixed reps, ≤6 sets, list the reps', () {
      final exercise = _bwExercise([_bwSet('8'), _bwSet('10'), _bwSet('12')]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), 'BW · 8/10/12');
    });
  });

  group('PlannedDraftSummaryFormatter.summarize — time-based', () {
    test('uniform duration with no weight renders "N×Ds"', () {
      final exercise = _timeExercise([
        _timeSet(duration: '30'),
        _timeSet(duration: '30'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '2×30s');
    });

    test('uniform duration with uniform weight renders "<kg>kg N×Ds"', () {
      final exercise = _timeExercise([
        _timeSet(duration: '30', weight: '20'),
        _timeSet(duration: '30', weight: '20'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '20kg 2×30s');
    });

    test('varying duration, no weight, ≤6 sets, lists durations', () {
      final exercise = _timeExercise([
        _timeSet(duration: '30'),
        _timeSet(duration: '45'),
      ]);
      expect(PlannedDraftSummaryFormatter.summarize(exercise), '30s/45s');
    });
  });
}

ExerciseDraft _repExercise(List<PlannedSetDraft> sets) => ExerciseDraft(
  draftId: 'ex',
  persistedId: null,
  name: 'Bench Press',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  plannedRestSeconds: null,
  sets: sets,
);

ExerciseDraft _bwExercise(List<PlannedSetDraft> sets) => ExerciseDraft(
  draftId: 'ex',
  persistedId: null,
  name: 'Pull-ups',
  measurementType: const MeasurementType.bodyweight(),
  metadata: ExerciseMetadata.empty,
  plannedRestSeconds: null,
  sets: sets,
);

ExerciseDraft _timeExercise(List<PlannedSetDraft> sets) => ExerciseDraft(
  draftId: 'ex',
  persistedId: null,
  name: 'Plank',
  measurementType: const MeasurementType.timeBased(),
  metadata: ExerciseMetadata.empty,
  plannedRestSeconds: null,
  sets: sets,
);

PlannedSetDraft _repSet({required String weight, required String reps}) =>
    PlannedSetDraft(
      draftId: 'set-${weight}_$reps',
      persistedId: null,
      values: PlannedSetDraftValues.repBased(
        weightInput: weight,
        repsInput: reps,
      ),
    );

PlannedSetDraft _bwSet(String reps) => PlannedSetDraft(
  draftId: 'bw-$reps',
  persistedId: null,
  values: PlannedSetDraftValues.bodyweight(repsInput: reps),
);

PlannedSetDraft _timeSet({required String duration, String? weight}) =>
    PlannedSetDraft(
      draftId: 'time-$duration-$weight',
      persistedId: null,
      values: PlannedSetDraftValues.timeBased(
        durationInput: duration,
        weightInput: weight ?? '',
      ),
    );
