---
inclusion: fileMatch
fileMatchPattern: 'lib/modules/**/screens/**.dart|lib/modules/**/widgets/**.dart|lib/building_blocks/**.dart'
---

# UI Tokens

Every UI file under `lib/modules/**/screens/`, `lib/modules/**/widgets/`, and
`lib/building_blocks/` reads colors, spacing, and typography from the
token files in `lib/core/`. Hard-coded pixel and `Color(0x...)` literals
inside widget code are not allowed.

## Tokens

- **Colors** — `lib/core/app_colors.dart`. Two palettes: `AppColors.dark`
  (default) and `AppColors.light`. Read from the active theme via
  `Theme.of(context).appColors` (extension declared in
  `lib/core/app_theme.dart`). Do **not** import `AppColors.dark` or
  `AppColors.light` directly from widget code — go through the theme so
  dark/light switching keeps working.
- **Spacing** — `lib/core/app_spacing.dart`. Use `AppSpacing.xs|sm|md|lg|xl|xxl|xxxl`
  for padding/gaps/margins. Interactive widgets must be at least
  `AppSpacing.touchMin` (48 dp) on their tap-target edge for one-handed
  use.
- **Radius** — `lib/core/app_spacing.dart` → `AppRadius.sm|md|lg|pill`.
- **Typography** — `lib/core/app_typography.dart`. For body text, prefer
  `Theme.of(context).textTheme.*` (already wired from `AppTypography`).
  Use `AppTypography.standard.numeric` / `numericLarge` (tabular figures)
  for weights, reps, durations, and timer readouts so digits do not
  jitter as values change.

## Semantic color rules

- **Planned vs actual** — `appColors.planned` for coach-authored targets,
  `appColors.actual` for what the user performed. Deviations are normal;
  keep the visual distinction subtle (weight, not hue).
- **Exercise state** — map `ExerciseState` to
  `exerciseCompleted` / `exerciseSkipped` / `exerciseReplaced`; use
  `onSurfaceMuted` for unfinished.
- **Rest timer** — `restTimer` for normal countdown, `restTimerOvertime`
  once the planned rest is exceeded.
- **Error / warning / success** — `error`, `warning`, `success`. Do not
  invent new semantic colors inside a widget; add a named field to
  `AppColors` instead.

## Adding or editing tokens

- Prefer adding a new semantic field to `AppColors`, `AppSpacing`, or
  `AppTypography` over introducing one-off values in a widget.
- Keep light and dark palettes in lockstep: every field on `AppColors`
  must have a value in both `AppColors.dark` and `AppColors.light`.
- When you add a new semantic field, update the "Semantic color rules"
  section above with the intended usage.

## Typography and numbers

- Headline/title text: `Theme.of(context).textTheme.titleLarge|titleMedium`.
- Body text: `textTheme.bodyLarge|bodyMedium`.
- Numeric readouts (weights, reps, durations, set counters, timers):
  `AppTypography.standard.numeric` for inline values;
  `AppTypography.standard.numericLarge` for focus-mode primary readouts.
- Do not set `fontFamily` inside widgets. The default platform font is
  intentional for MVP.

## Platform theme

`MainApp` wires `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()`,
and defaults `themeMode: ThemeMode.dark`. Any widget that needs to react
to brightness reads it through `Theme.of(context)`, never via
`WidgetsBinding.instance.platformDispatcher.platformBrightness`.
