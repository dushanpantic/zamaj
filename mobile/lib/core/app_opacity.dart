/// Opacity (alpha) scale for the Zamaj UI.
///
/// Mirrors [AppSpacing] / [AppRadius] / [AppIconSize] / [AppStroke]: alpha is a
/// design dimension like any other, so every `withValues(alpha: …)` reads a
/// named role here instead of a hand-picked literal. The same role takes the
/// same value everywhere — a "tinted fill" is [tintFill] in every file, not
/// 0.10 in one and 0.15 in the next.
///
/// Alpha is brightness-independent — it modulates whatever color it's applied
/// to — so this scale lives in one place rather than per-palette (unlike
/// `AppColors`, which has a dark and a light table).
///
/// For an opaque scrim/overlay layer behind a dialog or saving indicator, use
/// the `scrim` *color* token (`Theme.of(context).appColors.scrim`) directly —
/// it already bakes in its own alpha. Don't rebuild a scrim ad hoc as
/// `background.withValues(alpha: …)`.
abstract final class AppOpacity {
  /// Subtle wash of an accent color behind a notice/banner, badge, chip, or
  /// drag drop-target — the dominant "tinted fill" value. Collapses the old
  /// 0.10 / 0.12 / 0.15 / 0.18 fills onto one canonical step.
  static const double tintFill = 0.12;

  /// Fainter accent wash for a hover / drag-over hint where [tintFill] would
  /// read too strong.
  static const double tintFillSubtle = 0.08;

  /// Hairline border drawn over a [tintFill] (a notice/badge outline). Collapses
  /// the old 0.4 / 0.5 / 0.6 notice borders onto one canonical step.
  static const double borderTint = 0.4;

  /// Disabled / de-emphasized foreground or secondary glyph.
  static const double muted = 0.5;

  /// Focus-panel recede ladder (live surface only): the de-emphasis tint that
  /// fades a panel toward the background as it leaves "current". This is a
  /// *de-emphasis* effect, not modal elevation, so it stays a `surface` tint
  /// rather than collapsing onto `surfaceElevated`. [recede4] is the strongest
  /// (nearest "current"); [recede1] the faintest (furthest away).
  static const double recede1 = 0.18;
  static const double recede2 = 0.25;
  static const double recede3 = 0.3;
  static const double recede4 = 0.5;
}
