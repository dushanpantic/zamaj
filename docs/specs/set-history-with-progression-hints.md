# Spec: Set History with Progression Hints

## Intent Description

The solo lifter progresses each movement manually with a double-progression scheme — start a weight at a fixed rep target, widen to rep ranges, then bump the load and reset reps. The app deliberately never tells them what to lift, but today it gives them nothing at the moment they set next session's target. So they over-shoot (bump too soon, then fall a few reps short) or — more often — stall (keep capping a rep range and forget to tighten it or add weight). A real example: an elbow-rehab block where the lifter deliberately holds a reduced weight and hits every set, with no intent to progress.

This feature surfaces the planned-vs-actual record the lifter already logs, at the two moments the progression decision is actually made:

1. **In the exercise editor — a recent set-history table.** The last 5 completed sessions of the movement, each showing the planned target and the actual reps per set, with a marker when a session "capped" (all working sets met or exceeded the target ceiling).
2. **In the workout-day editor — a "needs attention" badge.** Flags any exercise whose recent history at the current prescription has been capped — i.e. a lift already maxed at its current weight + target that hasn't been advanced.

Everything is strictly descriptive: it shows what happened against the plan; the lifter still decides whether and how to advance (honoring the no-coaching non-goal). v1 is read-only — it derives entirely from existing session history and the program template, adding **no persisted state**.

## Architecture Specification

### Domain (pure Dart) — new

- **`CapHistory` / `CapHistoryEntry` models.** Newest-first list of recent session entries. Each entry carries: session date (`startedAt`), source program id + workout-day name, an ordered list of per-set `(PlannedSetValues, ActualSetValues)` pairs, and a derived `isCapped` flag. Measurement-type agnostic via the existing `PlannedSetValues` / `ActualSetValues` sealed types.
- **`ExerciseCapHistoryAggregator`** (pure-Dart service in `domain/services`, sibling of `ExerciseProgressAggregator`):
  - `computeHistory({required String libraryExerciseId, required List<Session> sessions, int limit = 5})` → `CapHistory`. Filters to ended sessions, attributes sets by the snapshot planned exercise's `libraryExerciseId` (same attribution path as `ExerciseProgressAggregator`), orders newest-first, takes `limit`.
  - `computeBadge({required List<WorkoutSet> currentPlannedSets, required String libraryExerciseId, required List<Session> sessions})` → `bool`. True iff, among ended sessions of the library entry whose snapshot planned sets equal `currentPlannedSets` (by planned value — weight + target, set-for-set, same count), **the most recent one capped**.
  - **Shared cap predicate.** Per working set, `actual ≥ ceiling`, where ceiling = `RepTargetFixed.reps` / `RepTargetRange.maxReps` (rep-based + bodyweight) or planned `durationSeconds` (time-based). A session caps iff **every** working set passes. Vary-by-set is judged per set against each set's own ceiling (no special-casing).

### Persistence

None. Reuses `SessionRepository.listCompletedSessions()`. **No schema-version change, no migration.**

### UI — exercise editor (`program_management/bloc/exercise_editor`, `screens/exercise_editor_screen.dart`)

- `ExerciseEditorBloc` gains a `SessionRepository` dependency (a **domain contract** — satisfies the UI-layer import rule), loads completed sessions, runs `computeHistory`, and exposes the resulting `CapHistory` plus the empty / unlinked-nudge states in `ExerciseEditorState`.
- The screen renders a "Recent history" section via `RecentSetHistorySection` (`program_management/widgets/recent_set_history_section.dart`): an unlinked nudge, a "No history yet" empty state, or ≤5 session rows inside a single bordered surface card, hairline-separated. Each row is one aligned line — compact date, planned summary (muted), per-set actuals (bright), and a quiet `▲` cap marker. Reuses `StatusBadge.icon` and `SetValueFormatter`; date labels come from the pure-Dart `RelativeDateFormatter.formatCompact` / `formatAbsolute` (core), with `now` read at build (precedent: `program_list_tile`). Pure presentation over the existing `RecentHistoryView` — **no new editor state/events and no extra repository calls**. Read-only display (no interactive controls); standard module ergonomics, not a sweaty-hands surface. Theme tokens only; numeric readouts use the tabular `numericSm` style.

### UI — workout-day editor (`program_management/bloc/workout_day_editor`, `screens/workout_day_editor_screen.dart`)

- `WorkoutDayEditorBloc` gains a `SessionRepository` dependency, loads completed sessions, computes `computeBadge` per exercise in the day — excluding warmup-group exercises (`warmupExerciseIdsIn`) and unlinked exercises — and exposes the badged exercise ids in state.
- The screen renders a token-based "needs attention" badge chip on each flagged exercise row (tap target ≥ 48 dp). Purely visual — **no tap action in v1**.

### Constraints

- `domain` stays pure Dart; aggregator exported via the `domain` barrel. UI accesses data only through `SessionRepository`; no Drift / `AppDatabase` / networking imports. Cross-module imports via barrels using `package:zamaj/...`.
- Copy is **descriptive only** — no imperative / recommendation language (no-coaching non-goal).
- Read-only derivation, recomputed live: a deleted session simply stops appearing (same property `ExerciseProgressAggregator` relies on).
- Performance: `listCompletedSessions()` loads all completed sessions; aggregation is O(sessions × exercises × sets), acceptable at single-user scale. A targeted repo query is a deferred optimization, not v1.
- Tests: domain aggregator + cap predicate fully unit-tested (project test scope: domain + persistence + module unit tests; no widget tests, no `bloc_test` package).

### Out of scope (deferred by decision)

- **Dismiss / hold suppression** of the badge → follow-up PR. v1 badge is always-on and cannot be silenced (accepted consequence: a deliberately-held rehab lift badges persistently).
- **Per-set warmup sets** — no per-set warmup axis exists today; when added, the cap predicate must consume the same warmup-set filter (extension point already noted in `nonWarmupCountsIn`).
- **Tap-a-row to open the session review**; **expand beyond 5 sessions**.

## Acceptance Criteria

### Cap predicate
- **AC1** — Rep-range target (e.g. 10–12): capped iff every working set's reps ≥ 12. `12·12·12` caps; `12·12·11` does not.
- **AC2** — Fixed rep target (e.g. 12): capped iff every working set's reps ≥ 12.
- **AC3** — Time-based target: capped iff every working set's duration ≥ the planned seconds.
- **AC4** — Reps/duration that exceed the ceiling still count as capped.
- **AC5** — Bodyweight targets use the same rep-ceiling rule as rep-based.
- **AC6** — Vary-by-set / descending (drop set) plans are judged per set against each set's own ceiling — no special-casing (so a descending drop set generally does not cap).

### History table (exercise editor)
- **AC7** — Shows up to the 5 most recent ended sessions of the movement (matched by `libraryExerciseId`), newest first.
- **AC8** — Aggregates across every program the movement appears in.
- **AC9** — Populated history renders as one bordered surface card holding one row per entry, newest first, hairline-separated (no divider above the first or below the last row); a single entry shows no divider. Each row is one line: date column, planned summary, per-set actuals, trailing cap-marker slot.
- **AC9a** *(date)* — The date column reads compactly: "Today"/"Yesterday" for 0/1 days back, an abbreviated weekday ("Tue") for 2–6 days back, else short month + day ("Jun 5") — with the year appended only when the entry's year differs from today's. The unabbreviated absolute date ("Jun 5, 2024") is always available via the column's tooltip / semantic label. (Supersedes the original "absolute date" rendering.)
- **AC9b** *(emphasis)* — Planned always renders in the muted `planned` color; actuals render in the bright `actual` color **when at least one set was logged** and in the muted `onSurfaceMuted` color when none were (the "—" case) — matching the planned/actual emphasis of the in-session and session-review set rows. Both columns use the tabular `numericSm` style and truncate to a single line with ellipsis on overflow.
- **AC9c** *(cap marker)* — A capped session shows the `▲` glyph (`Icons.arrow_drop_up`, `exerciseCompleted` color) in the reserved trailing slot, with its description carried only in the tooltip + semantic label ("Capped — top of range" / "— hit target" / "— hit time", or "Capped" when the target kind is indeterminate) — **no descriptive caption is rendered inline**. A non-capped session leaves the slot empty but width-reserved, so the actuals column's right edge stays aligned across capped and uncapped rows. (Supersedes the original inline-caption rendering.)
- **AC9d** *(skipped-in-session entry)* — A completed session that logged **zero** sets of the movement still produces a row (the aggregator attributes by snapshot, not by logged count): it shows the planned summary, "—" muted actuals, and **no** cap marker (`isCapped` is false because no working set was executed).
- **AC9e** *(partial entry / defensive)* — A session with **fewer** logged sets than planned shows only the logged sets' actuals (bright) and no cap marker; a session with **more** logged sets than planned shows all logged sets. When an entry's planned-set list is empty (defensive — exercises normally have ≥1 set), the planned summary renders "—".
- **AC10** — A linked exercise with no ended sessions shows the "No history yet" empty state (plain muted text, not a card).
- **AC11** — An unlinked exercise shows the "link to a library entry to see history" nudge and no rows.
- **AC12** — A warmup-group exercise shows no history section and no cap markers.

### Attention badge (workout-day editor)
- **AC13** — An exercise is badged iff, among ended sessions of its library entry whose snapshot planned sets equal the exercise's current planned sets (weight + target, set-for-set, same count), the most recent one capped.
- **AC14** — The badge fires after a single capped session.
- **AC15** — The badge clears when the plan advances — target tightened (10–12 → 12), weight increased, or any change making current planned sets ≠ the capped session's — because no matching capped session remains.
- **AC16** — A warmup-group exercise is never badged.
- **AC17** — An unlinked exercise is never badged.
- **AC18** — Each program/day badges against its own weight + target; the same movement done at a different load in another program does not cross-trigger.

### Non-functional / constraints
- **AC19** — No schema-version change and no migration are introduced.
- **AC20** — No networking or Drift / `AppDatabase` imports in `domain` or UI; UI accesses session data only via `SessionRepository`.
- **AC21** — All new UI uses theme tokens (no hard-coded px / color literals); badge tap target ≥ 48 dp.
- **AC22** — All copy is descriptive; no recommendation / imperative text.
- **AC23** — The domain aggregator and cap predicate have unit tests covering the derivation logic behind AC1–AC18.
- **AC23a** — The compact / absolute date-label logic behind AC9a is unit-tested in `RelativeDateFormatter` (core test scope), covering the Today / Yesterday / weekday / month-day branches, the cross-year year suffix, and UTC→local conversion.
- **AC24** — `product-context.md` is updated to reflect the new capability on the exercise-editor and workout-day-editor screens.

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts
- [x] No contradictions between artifacts — AC9a/AC9c explicitly supersede the original "absolute date" and inline-caption rendering; no stale claim remains.

## Revisions
- **2026-06-17 — history-table presentation tightened.** The exercise-editor "Recent history" rows were redesigned: actuals now carry the bright `actual` emphasis (planned muted), dates read relative + short-month with the full date in a tooltip, the cap marker is a quiet `▲` glyph with its phrase in the tooltip, and rows sit in a bordered surface card. AC9 was split into AC9–AC9e to specify the new layout and to cover the previously-unspecified **skipped-in-session** (zero logged sets → muted "—" actuals, no marker) and **partial / empty-planned** edge cases. Domain ACs (AC1–AC18) and the aggregator are unchanged. Decision: skipped-in-session entries remain visible (informative "you skipped it that day"), muted rather than hidden — matching the absent-actual treatment on the session-review set row.
