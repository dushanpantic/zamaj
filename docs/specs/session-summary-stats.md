# Spec: Session Summary Stats

## Intent Description

After a lifter ends a workout, the app currently gives no acknowledgement of what they
just did — ending a session drops them back to the overview behind a thin "Session ended"
banner, and opening a past session from history shows only a set-by-set list with no
header. The single question a lifter asks when they finish ("how did that go?") goes
unanswered even though the data to answer it is already stored.

This change surfaces three headline numbers — **duration**, **sets completed (of planned)**,
and **total volume lifted** — at the two moments that question is asked: immediately after
ending a session on the workout overview screen, and when reopening a finished session from
history. The numbers are a pure read over the already-persisted `Session`; nothing is
written, no snapshot is mutated, and a completed session's stats never change unless the
user corrects a logged value (which already re-renders the screen).

The presentation follows the category convention (Hevy, Strong): a small set of clean
headline figures with no disclaimers. Volume sums weighted work only; bodyweight and
time-based sets still count toward the set total but contribute nothing to volume, and the
volume figure is omitted entirely when a session has no weighted sets, so an all-bodyweight
day never shows a broken "0 kg".

## Architecture Specification

### New domain computation (single source of truth)
- A pure value object, `SessionSummary`, plus a factory `SessionSummary.fromSession(Session)`,
  lives in `lib/modules/domain/` (pure Dart, no Flutter). Exposes:
  - `Duration duration` — `endedAt - startedAt`.
  - `int completedWorkingSets` — count of `ExecutedSet` across `sessionExercises`, excluding
    warmup-group exercises.
  - `int plannedWorkingSets` — count of planned `WorkoutSet`s in `session.snapshot.workoutDay`,
    excluding warmup groups.
  - `double weightedVolumeKg` — `Σ(weightKg × reps)` over `ActualRepBased` executed sets in
    working (non-warmup) exercises. `ActualBodyweight` and `ActualTimeBased` contribute 0.
  - `bool hasWeightedVolume` — true iff at least one weighted working set was logged; gates
    whether the volume figure renders.
- Warmup exclusion reuses the existing `isWarmupGroup` helper / the warmup-id derivation used
  by `SessionExportFormatter` (`lib/modules/domain/services/session_export_formatter.dart`).
  Do **not** reimplement warmup detection — extract a shared helper if the export's logic is
  not already callable.

### Shared presentation
- A presentational widget renders a `SessionSummary` and is reused by both surfaces, placed
  where both modules may import it (`lib/building_blocks/`). It owns layout and token usage;
  it holds no business logic and performs no computation.
- Numeric readouts use `AppTypography.standard.numeric` (tabular figures). Colors via
  `Theme.of(context).appColors`; completion/positive accent via the existing
  `exerciseCompleted` semantic color. No hard-coded pixels or color literals.
- Duration formatting (`mm:ss` / `h:mm:ss`) must match the existing
  `SessionElapsedLabel._formatElapsed`. Extract that formatter to a shared location and have
  both call it rather than introducing a third copy.

### Surface 1 — Workout overview, post-end
- Replace the body of `SessionEndedBanner`
  (`lib/modules/workout_overview/widgets/session_ended_banner.dart`) so the banner becomes a
  summary card: the three stats plus the retained "Completed sets remain editable." line.
- Renders only when `state.isEnded` (already the banner's gate in
  `workout_overview_loaded_body.dart`), so `endedAt` is always set and duration is final.
- This surface is the live-session ("sweaty-hands") module, but the card is a read-only
  display, not a control — the 56 dp tap-target floor does not apply; legibility is the goal.

### Surface 2 — Session detail (history)
- Add the summary card as a header above the exercise list in
  `lib/modules/export/screens/session_detail_screen.dart`, fed by
  `SessionSummary.fromSession(state.session)` from the already-loaded `SessionDetailLoaded`.
- No "editable" footer line here (that hint is the overview's concern); the card shows the
  three stats only.

### Constraints / boundaries
- No new persistence, no new repository method, no Drift migration, no `schema_versions` bump.
- No networking; computation stays in `domain` (offline-first layer rules hold).
- The frozen snapshot is read, never written. A value correction on an editable in-week
  session flows through the existing `watchSession` stream and re-renders the card; no extra
  wiring needed.
- Cross-module imports go through barrels (`domain.dart`, `building_blocks.dart`).

## Acceptance Criteria

1. **Duration is correct and final.** For an ended session, the card shows
   `endedAt - startedAt`, formatted `mm:ss` under one hour and `h:mm:ss` at/over one hour,
   identical to the app-bar elapsed label.
2. **Sets read "X of Y".** X = completed working (non-warmup) executed sets; Y = planned
   working (non-warmup) sets in the snapshot. Warmup-group sets are excluded from both. When
   extra sets push completed past planned, X may exceed Y and is shown as-is (e.g. "22 of 20").
3. **Volume sums weighted work only.** `weightedVolumeKg = Σ(weightKg × reps)` over weighted
   (repBased) working executed sets; bodyweight and time-based sets add 0.
4. **Volume is omitted when there is none.** A session with zero weighted working sets renders
   no volume figure (not "0 kg"); duration and sets still render.
5. **Both surfaces show identical numbers** for the same session, because both derive from the
   single `SessionSummary.fromSession`. No second computation path exists.
6. **Overview card replaces the old banner** post-end, retains the "Completed sets remain
   editable." line, and renders only when the session is ended.
7. **History card** appears as a header above the set list on the session detail screen for any
   finished session.
8. **Correcting a logged value updates the stats.** Editing a set value on an editable in-week
   session re-renders the card with recomputed sets/volume via the existing watch stream — no
   manual refresh.
9. **No persistence or schema change.** No migration, no `schema_versions` bump, no new repo
   method; the change is read-only over existing data.
10. **Token & layer compliance.** No hard-coded pixels or color literals in the new widget;
    `domain` computation imports no Flutter/Drift/networking; `tool/check_offline_imports.sh`
    and `tool/ci.sh` pass.

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts ("working sets", "weighted volume", "summary card")
- [x] No contradictions between artifacts
