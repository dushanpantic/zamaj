/// Opacity (alpha) scale for the Zamaj UI: every `withValues(alpha: …)` reads a
/// named role here instead of a hand-picked literal.
///
/// Alpha is brightness-independent, so this scale lives in one place rather than
/// per-palette (unlike [AppColors], which has a dark and a light table).
///
/// For an opaque scrim/overlay behind a dialog or saving indicator, use the
/// `scrim` color token (`Theme.of(context).appColors.scrim`) directly — it
/// already bakes in its own alpha; don't rebuild one as
/// `background.withValues(alpha: …)`.
abstract final class AppOpacity {
  /// Subtle wash of an accent color behind a notice/banner, badge, chip, or
  /// drag drop-target — the dominant "tinted fill" value.
  static const double tintFill = 0.12;

  /// Fainter accent wash for a hover / drag-over hint where [tintFill] would
  /// read too strong.
  static const double tintFillSubtle = 0.08;

  /// Hairline border drawn over a [tintFill] (a notice/badge outline).
  static const double borderTint = 0.4;

  /// Reorder drop-target line: [dropTargetActive] is the brighter accent line
  /// shown while a drag is in progress and this gap is a live target;
  /// [dropTargetIdle] is the faint resting line drawn between rows.
  static const double dropTargetActive = 0.55;
  static const double dropTargetIdle = 0.4;

  /// Secondary/supporting label over a filled accent surface (e.g. the sub-label
  /// under a primary action button's main label). Softly de-emphasized but still
  /// prominent — a gentler step than [muted].
  static const double labelSecondary = 0.75;

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
