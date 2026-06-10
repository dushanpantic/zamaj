/// Spacing scale used across the Zamaj UI.
///
/// Every padding/gap/margin reads from [AppSpacing] instead of hard-coded
/// pixel values. [touchMin] is the minimum one-handed-friendly tap target
/// edge; keep interactive widgets at or above this size.
abstract final class AppSpacing {
  /// Hairline gap, half a step below [xs] — e.g. the vertical inset of a
  /// compact status pill. Use sparingly; [xs] is the normal floor.
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double touchMin = 48;

  /// Minimum height for a full-width inline banner — e.g. the "Workout in
  /// progress" strip. A *min-height*, not a tap-target floor: the banner grows
  /// past this when its text wraps at large font sizes. Distinct in role from
  /// [touchMin] (the 48 dp interactive floor) and the live-session-only
  /// [AppInSessionSize.controlMin] (56 dp control floor), with which it happens
  /// to share a value.
  static const double bannerMin = 56;

  /// Height for compact, sub-[touchMin] inline secondary actions — e.g. the
  /// "Edit day" peek button or an "Open video" link. These are dense, low-stakes
  /// affordances, not primary or live-session sweaty-hands controls, so a height
  /// below [touchMin] is deliberate.
  static const double compactAction = 36;
}

/// Corner radius scale paired with [AppSpacing].
abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 16;
  static const double pill = 999;
}

/// Border / divider stroke widths, paired with [AppSpacing].
///
/// [hairline] is the default 1 px outline on cards, dividers, and pills;
/// [emphasis] is the 2 px stroke reserved for focused / active borders.
abstract final class AppStroke {
  static const double hairline = 1;
  static const double emphasis = 2;

  /// Stroke width for a standard [CircularProgressIndicator] (16–24 dp).
  static const double indicator = 2;

  /// Thinner indicator stroke for compact inline spinners (~12 dp), e.g. the
  /// save-state chip, where the full [indicator] stroke reads too heavy.
  static const double indicatorCompact = 1.5;
}

/// Diameter scale for the inline progress spinner (`AppInlineSpinner`).
///
/// A small named scale so inline spinners pick a step instead of a raw pixel
/// size: [sm] inside a dense chip/caption row, [md] (the default) for an inline
/// button or app-bar slot, [lg] for a prominent inline wait such as a deleting
/// list tile.
abstract final class AppSpinnerSize {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

/// In-session (sweaty-hands) control sizes for the live-session surface
/// (`workout_overview/`, `focus_mode/`).
///
/// These encode the CLAUDE.md sweaty-hands rule as tokens, so a new in-session
/// control inherits the right floor instead of re-deriving `64` / `56` by hand.
/// Everywhere *else* the normal [AppSpacing.touchMin] (48 dp) floor applies —
/// reach for these only under the two live modules.
abstract final class AppInSessionSize {
  /// Step / counter (± bump) button edge / height — 64 dp.
  static const double stepButton = 64;

  /// Primary in-session action height (LOG SET / SAVE) — 64 dp.
  static const double primaryAction = 64;

  /// Floor for secondary in-session controls that aren't a stepper or the
  /// primary action (e.g. the rest-timer SKIP) — 56 dp.
  static const double controlMin = 56;
}
