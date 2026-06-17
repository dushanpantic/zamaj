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
      actualsText: _actualsSummary(entry.actualSets),
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

  /// The per-set reps / holds, joined — e.g. `12 · 12 · 11` or `45s · 50s`.
  static String _actualsSummary(List<ActualSetValues> actuals) {
    if (actuals.isEmpty) return '—';
    return actuals
        .map(
          (a) => switch (a) {
            ActualRepBased(:final reps) => '$reps',
            ActualBodyweight(:final reps) => '$reps',
            ActualTimeBased(:final durationSeconds) => '${durationSeconds}s',
          },
        )
        .join(' · ');
  }

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
