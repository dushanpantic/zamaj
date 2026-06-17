import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// The strings and flags one recent-history row renders, derived purely from a
/// [CapHistoryEntry]. Holds no Flutter or token concerns — the widget owns
/// colour and style; this owns "what text, and is it the empty/muted case".
class RecentHistoryRowView {
  const RecentHistoryRowView({
    required this.plannedText,
    required this.actualsText,
    required this.actualsAreMuted,
    required this.capDescription,
  });

  /// The planned weight + target read off the first planned set
  /// ("100kg × 8–12"), or "—" when the entry carries no planned sets.
  final String plannedText;

  /// The per-set actuals joined by " · " ("12 · 12 · 11"), or "—" when no set
  /// was logged.
  final String actualsText;

  /// True when no set was logged (the "—" case): the widget renders the
  /// actuals muted rather than in the bright actual colour.
  final bool actualsAreMuted;

  /// The cap detail by planned target kind ("top of range" / "hit target" /
  /// "hit time" / "capped"), or null when the session did not cap (no marker).
  final String? capDescription;

  /// Whether a cap marker should render.
  bool get isCapped => capDescription != null;

  /// The marker's full accessible label — "Capped — top of range", or just
  /// "Capped" when the target kind is indeterminate. Null when not capped.
  String? get capTooltip {
    final detail = capDescription;
    if (detail == null) return null;
    return detail == 'capped' ? 'Capped' : 'Capped — $detail';
  }
}

/// Pure mapping from a [CapHistoryEntry] to its [RecentHistoryRowView].
/// Extracted from the recent-history widget so the row's text + cap derivation
/// is unit-testable without a widget test.
abstract final class RecentHistoryRowPresenter {
  static RecentHistoryRowView present(CapHistoryEntry entry) {
    return RecentHistoryRowView(
      plannedText: _plannedSummary(entry.plannedSets),
      actualsText: _actualsSummary(entry.plannedSets, entry.actualSets),
      actualsAreMuted: entry.actualSets.isEmpty,
      capDescription: entry.isCapped ? _capCaption(entry.plannedSets) : null,
    );
  }

  /// The planned weight + target for the session, read off its first planned
  /// set. Reuses the in-app planned formatter so the readout matches the set
  /// rows.
  static String _plannedSummary(List<PlannedSetValues> planned) {
    if (planned.isEmpty) return '—';
    final first = planned.first;
    return SetValueFormatter.formatPlanned(first, _measurementTypeOf(first));
  }

  /// The per-set actuals, joined. Weight is surfaced only when a logged set
  /// strayed from its planned weight, so the common on-plan case stays clean and
  /// leans on the planned column for the weight:
  ///
  /// * on plan → reps / holds only (`12 · 12 · 11`);
  /// * off plan, one weight across every set → a leading tag (`@40kg 8 · 8 · 8`)
  ///   — leading so it survives the column's end-ellipsis;
  /// * off plan, weights varying between sets → per-set (`40 × 8 · 45 × 8`).
  static String _actualsSummary(
    List<PlannedSetValues> planned,
    List<ActualSetValues> actuals,
  ) {
    if (actuals.isEmpty) return '—';

    final weights = [for (final a in actuals) _actualWeightOf(a)];
    var anyStrayed = false;
    for (var i = 0; i < actuals.length; i++) {
      final plannedWeight = i < planned.length
          ? _plannedWeightOf(planned[i])
          : null;
      if (weights[i] != null &&
          plannedWeight != null &&
          weights[i] != plannedWeight) {
        anyStrayed = true;
      }
    }

    if (!anyStrayed) return actuals.map(_repsOnly).join(' · ');

    final distinct = weights.whereType<double>().toSet();
    if (distinct.length == 1 && !weights.contains(null)) {
      return '@${WeightFormatter.formatKg(distinct.first)}kg '
          '${actuals.map(_repsOnly).join(' · ')}';
    }
    return actuals.map(_weightAndReps).join(' · ');
  }

  /// One set's reps / hold without weight — `12` or `45s`.
  static String _repsOnly(ActualSetValues a) => switch (a) {
    ActualRepBased(:final reps) => '$reps',
    ActualBodyweight(:final reps) => '$reps',
    ActualTimeBased(:final durationSeconds) => '${durationSeconds}s',
  };

  /// One set's weight × reps / hold — `40 × 8` or `40 × 45s`; weightless sets
  /// fall back to reps / hold only.
  static String _weightAndReps(ActualSetValues a) => switch (a) {
    ActualRepBased(:final weightKg, :final reps) =>
      '${WeightFormatter.formatKg(weightKg)} × $reps',
    ActualTimeBased(:final durationSeconds, :final weightKg) =>
      weightKg == null
          ? '${durationSeconds}s'
          : '${WeightFormatter.formatKg(weightKg)} × ${durationSeconds}s',
    ActualBodyweight(:final reps) => '$reps',
  };

  /// The logged weight of a set, or null for a weightless (bodyweight or
  /// unweighted hold) set.
  static double? _actualWeightOf(ActualSetValues a) => switch (a) {
    ActualRepBased(:final weightKg) => weightKg,
    ActualTimeBased(:final weightKg) => weightKg,
    ActualBodyweight() => null,
  };

  /// The planned weight of a set, or null for a weightless set.
  static double? _plannedWeightOf(PlannedSetValues p) => switch (p) {
    PlannedRepBased(:final weightKg) => weightKg,
    PlannedTimeBased(:final weightKg) => weightKg,
    PlannedBodyweight() => null,
  };

  /// Descriptive caption for the cap marker, by planned target kind.
  static String _capCaption(List<PlannedSetValues> planned) {
    final first = planned.isEmpty ? null : planned.first;
    return switch (first) {
      PlannedRepBased(:final repTarget) ||
      PlannedBodyweight(
        :final repTarget,
      ) => repTarget is RepTargetRange ? 'top of range' : 'hit target',
      PlannedTimeBased() => 'hit time',
      null => 'capped',
    };
  }

  static MeasurementType _measurementTypeOf(PlannedSetValues planned) =>
      switch (planned) {
        PlannedRepBased() => const MeasurementType.repBased(),
        PlannedTimeBased() => const MeasurementType.timeBased(),
        PlannedBodyweight() => const MeasurementType.bodyweight(),
      };
}
