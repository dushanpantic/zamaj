# UX plan — Program list screen

Status: proposal / not yet implemented
Scope: `mobile/lib/modules/program_management` — the **Program list** screen
([program_list_screen.dart](mobile/lib/modules/program_management/screens/program_list_screen.dart)
and [program_list_tile.dart](mobile/lib/modules/program_management/widgets/program_list_tile.dart)).

This is a planning document. It does not change behaviour on its own. It is
grounded in the existing design tokens, the app's own established list idioms,
and the product non-goals in [product-context.md](product-context.md).

---

## 1. Why this screen matters

Program list is the app's **home screen** — it is the `initialRoute`
([app.dart:52](mobile/lib/app.dart#L52)). It is the first thing the lifter sees
on launch and the hub they pass through to start every workout. Despite that, it
currently carries the *least* information of any list in the app.

The user's job-to-be-done here is almost always one of:

1. **"Open my current program and start today's day."** (most frequent)
2. "Resume the workout I'm in the middle of."
3. "Edit / fix a program."
4. "Create or import a new program." (rare, mostly one-time)

The screen should make #1 and #2 instant and obvious, keep #3 reachable but not
loud, and keep #4 discoverable without crowding the common path.

---

## 2. Current-state audit

### What it does today

- **AppBar** `Programs` + two icon-only actions: exercise library, text import
  ([program_list_screen.dart:88-101](mobile/lib/modules/program_management/screens/program_list_screen.dart#L88-L101)).
- **Extended FAB** `New program`.
- **Body**: `SessionInFlightBanner` (a slim global "resume" strip) + a
  `ListView.separated` of tiles, sorted by `updatedAt` desc then name
  ([program_list_bloc.dart:86-90](mobile/lib/modules/program_management/bloc/program_list/program_list_bloc.dart#L86-L90)).
- **Tile** ([program_list_tile.dart](mobile/lib/modules/program_management/widgets/program_list_tile.dart)):
  program name (titleSmall) + relative `updatedAt` (caption); trailing
  `more_vert` menu (Edit / Delete) or a delete spinner; swipe-to-delete
  (`Dismissible`) → confirmation dialog. Tap routes to editor (0 days) or day
  picker (≥1 day).
- **States**: loading = bare centered spinner; failure = icon + retry; empty =
  icon + two CTAs (good); loaded = the list.

### Problems (mapped to UX principles in §3)

| # | Problem | Heuristic violated |
|---|---------|--------------------|
| P1 | **Almost no information scent.** Tile shows only name + edited date. No day count, no size, no "last trained", no sense of structure. The day count is already in memory (`program.workoutDayIds.length`) and simply not rendered. | Recognition over recall; visibility of system state |
| P2 | **Tap outcome is unpredictable.** Same-looking card opens the *editor* (0 days) or the *day picker* (≥1 day). Nothing signals which. | Match between system and the real world; consistency; user control |
| P3 | **No primary-action emphasis on the home screen.** The dominant verb is "start a workout," but the tile reads as a passive label. Resume lives in a separate global banner, disconnected from the program it belongs to. | Visibility of system status; aesthetic & minimalist (signal vs noise) |
| P4 | **Inconsistent with the app's own idioms.** The day picker tile and the editor day tile already use counts, pill chips (`IN PROGRESS`, `EMPTY`), a 4px accent bar, and skeleton loaders. The program-list tile uses none of them — it's the visual odd-one-out. | Consistency and standards |
| P5 | **Loading is a bare spinner**, while the rest of the app uses skeletons (see [day_tile.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart) `_Skeleton`). | Consistency; perceived performance |
| P6 | **Flat visual hierarchy / weak scannability.** Uniform low-contrast rows with no leading anchor; hard to scan once there are several programs. | Aesthetic-usability; visual hierarchy |
| P7 | **Empty programs are invisible as such.** A 0-day "draft" looks identical to a fully-built program until you tap it and land somewhere unexpected (ties to P2). | Visibility of system status |
| P8 | **A11y gaps.** Delete is reachable without swipe (good — popup menu), but tiles lack composed semantic labels, the date has no "Edited" prefix for screen readers, and large text scaling on the single caption row is untested. | Accessibility / inclusivity |

### What's already good (keep it)

- Empty state: icon + headline + subcopy + a primary and a secondary CTA — this
  is a textbook empty state. Keep, light polish only.
- Failure state: icon + message + `Retry` `FilledButton`. Keep.
- Delete is **confirmed** (dialog) and reachable two ways (swipe + menu).
- FAB bottom padding already clears the last list item.
- Sort (most-recently-edited first) puts the likely "current" program on top.

---

## 3. Deep dive — modern UI/UX best practices applied here

A synthesis of established mobile/product UX principles (Nielsen's heuristics,
Material 3 list guidance, Fitts's & Hick's laws, progressive disclosure,
information scent), each translated into a concrete decision for *this* screen.
Everything below is filtered through the product's **non-goals**: no social, no
streaks, no badges, no gamification, no "coaching." Improvements are about
**clarity and speed**, never engagement mechanics.

1. **Recognition over recall / information scent.** People recognise a program
   by its *shape* ("the 4-day push/pull one"), not its name alone. → Surface
   structure on the tile: day count now (free), exercise count later.

2. **Visibility of system status.** The home screen should answer "where am I?"
   at a glance. → Reflect an in-progress session *on the owning program's card*
   (accent bar + `IN PROGRESS` chip), not only in a detached banner.

3. **Match & predictability of actions (affordances/signifiers).** A control
   should signal what it does before you touch it. → Make empty/draft programs
   visibly different so the "opens the editor" outcome is expected (fixes P2/P7).

4. **Visual hierarchy & the aesthetic-usability effect.** A leading anchor plus
   a clear primary/secondary/tertiary type rhythm makes a list scannable and
   feels more trustworthy. → Add a leading anchor (program initial), name as
   primary, structure as secondary, timestamp as tertiary.

5. **Consistency & standards (internal first).** The strongest "best practice"
   here is to match the app's *own* vocabulary. → Reuse the existing pill-chip,
   accent-bar, and skeleton patterns rather than inventing new ones.

6. **Progressive disclosure.** Keep the card scannable; push detail and
   destructive actions behind a tap/menu. → Counts on the card; Edit/Delete stay
   in the overflow menu; no inline clutter.

7. **Feedback & perceived performance.** Skeletons communicate "content is
   coming" better than a spinner and reduce perceived latency. → Skeleton list
   while loading.

8. **Fitts's law / touch ergonomics.** This screen is **outside** the
   sweaty-hands zone, so the standard 48 dp (`AppSpacing.touchMin`) is the
   correct target — do **not** over-size to 56–64 dp here (that rule is scoped to
   `workout_overview/` and `focus_mode/` per [CLAUDE.md](CLAUDE.md)).

9. **Hick's law / restraint.** Don't add search, sort pickers, tags, or filters
   for a single-user library of a handful of programs — that's speculative
   complexity. Note them as deferred (§6.3), don't build them.

10. **Error prevention & reversibility.** Keep delete confirmed; keep two paths
    to it; consider an Undo-on-delete only if cheap (deferred).

11. **Accessibility as a baseline.** Composed semantic labels, "Edited" prefix
    for the date, decorative anchor excluded from the a11y tree, graceful text
    scaling, and never relying on swipe alone (already satisfied via the menu).

---

## 4. Design direction

A tile that matches the app's existing list vocabulary, carries real
information scent, and makes the tap outcome predictable.

### 4.1 Tile anatomy (target)

```
┌────────────────────────────────────────────────────────────┐
│ ▌ ┌────┐  PPL Hypertrophy Block          [IN PROGRESS]  ⋮  │   ← accent bar (▌) only
│ ▌ │ P  │  4 days · 23 exercises · Edited Tuesday              when this program
│   └────┘                                                      holds the active session
└────────────────────────────────────────────────────────────┘

Empty / draft program:
┌────────────────────────────────────────────────────────────┐
│   ┌────┐  New Program            [DRAFT]                  ⋮  │
│   │ N  │  No days yet · Tap to set up                         │
│   └────┘                                                      │
└────────────────────────────────────────────────────────────┘
```

- **Leading anchor**: rounded square (`AppRadius.md`, `surfaceVariant` bg,
  48 dp) showing the program's first letter (uppercased). Quick differentiation
  when several programs are listed. Decorative → excluded from semantics. For the
  in-progress program, tint it with `primary`.
- **Title**: `program.name`, `typography.titleSmall`, `colors.onSurface`,
  1 line, ellipsis.
- **Chips** (right of title, optional): `IN PROGRESS` (primary pill — reuse the
  exact idiom from [day_tile.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L196-L216))
  or `DRAFT` (muted/`onSurfaceMuted` pill) when the program has 0 days.
- **Metadata row**: `typography.caption`, `colors.onSurfaceMuted`. Composed with
  the existing `·` separator idiom: `"{n} days"` now; `"· {m} exercises"` in
  Phase 2; `"· Edited {relativeDate}"` always. Empty program → `"No days yet ·
  Tap to set up"`.
- **Accent bar**: 4 px left bar in `colors.primary`, shown only for the
  in-progress program (mirrors [day_tile.dart:102-125](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L102-L125)).
  Use `AppSpacing.xs` (4) for the width rather than a raw literal.
- **Trailing**: keep the `more_vert` overflow menu (Edit / Delete) and the delete
  spinner exactly as today. No chevron — the anchor + whole-card InkWell already
  signal tappability, and a chevron beside a menu is redundant clutter.
- **Tap**: unchanged routing (editor for 0-day, picker otherwise), but now the
  `DRAFT` chip + "Tap to set up" copy makes the editor outcome expected (P2/P7).
- Swipe-to-delete `Dismissible` and the confirmation dialog: unchanged.

### 4.2 Screen-level

- **Loading** → skeleton list of ~4 placeholder tiles reusing the
  `_SkeletonBar` pattern (extract a shared skeleton tile). Replaces the bare
  spinner (P5).
- **Empty / failure** → keep; minor copy/spacing polish only.
- **AppBar** → keep the two icon actions; they have tooltips. Low priority:
  consider whether "Exercise library" (a sibling destination, not a program
  action) belongs in an overflow `⋮` to reduce top-bar noise. Decision deferred
  to the user (§7).
- **FAB** `New program` → keep; it is the correct, single, prominent create
  affordance.
- **Sort** → keep `updatedAt` desc. Do **not** auto-pin the in-progress program
  to the top; the accent bar already draws the eye, and reordering on
  session-start would be a surprising jump.

---

## 5. Phased implementation plan

Phases are independently shippable and ordered by value-to-risk. **Phase 1 is
the recommended baseline** and delivers most of the perceived improvement with
zero data-layer changes.

### Phase 1 — Tile redesign, UI-only (no repo/bloc/state changes)

**Goal:** information scent + consistency + predictability using only data
already loaded into `ProgramListLoaded.programs`.

Data used: `program.name`, `program.workoutDayIds.length` (day count, free),
`program.updatedAt`. In-progress detection via the existing
`watchActiveSession()` stream (already consumed on this screen by
`SessionInFlightBanner`).

Changes:

1. **Rewrite `ProgramListTile`** ([program_list_tile.dart](mobile/lib/modules/program_management/widgets/program_list_tile.dart))
   to the §4.1 anatomy:
   - Add leading initial anchor (decorative, `Semantics(excludeSemantics: …)` or
     wrapped so SR reads the composed label only).
   - Add metadata row: `"{dayCount} day(s)"` + `" · Edited {relativeDate}"`;
     0-day → `"No days yet · Tap to set up"`.
   - Add `DRAFT` chip when `program.workoutDayIds.isEmpty`; reuse the pill idiom
     (`primary`/`onSurfaceMuted` low-alpha bg + 0.5-alpha border + `badge` type).
   - Keep the `more_vert` menu, delete spinner, `Dismissible`, and tap routing
     exactly as they are.
   - Add a composed `Semantics(button: true, label: "{name}, {metadata}")` on the
     tappable region.
2. **In-progress reflection** (optional within Phase 1, recommended): wrap the
   list in a `StreamBuilder<Session?>` on `context.read<SessionRepository>()
   .watchActiveSession()` (same source as the banner), pass
   `activeProgramId = session?.snapshot.workoutDay.programId` down, and render the
   accent bar + `IN PROGRESS` chip on the matching tile. No bloc change — this is
   a read-only stream the screen already has access to.
3. **Skeleton loading view**: replace `_LoadingView`'s spinner
   ([program_list_screen.dart:174-183](mobile/lib/modules/program_management/screens/program_list_screen.dart#L174-L183))
   with a non-interactive list of ~4 skeleton tiles. Extract a small
   `_ProgramTileSkeleton` (or a shared `lib/building_blocks/` skeleton — see §6)
   from the `_SkeletonBar` pattern in `day_tile.dart`.
4. **Token cleanup**: ensure the 4 px accent bar uses `AppSpacing.xs`, not a raw
   literal (avoids repeating the `width: 4` literal in `day_tile.dart`).

**Acceptance criteria**
- Each loaded tile shows name + day count + relative edited date.
- A 0-day program shows a `DRAFT` chip and "Tap to set up" subtext; tapping it
  opens the editor (unchanged route, now expected).
- When a session is in flight, exactly one tile (the owning program) shows the
  accent bar + `IN PROGRESS` chip.
- Loading shows skeleton tiles, not a spinner.
- No new hard-coded colors/pixels; all tokens via `appColors` / `AppSpacing` /
  `AppRadius` / `AppTypography` (enforced by `tool/check_offline_imports.sh` for
  the layering rules; tokens are a code-review check).
- No import of `drift`/`AppDatabase`/`HttpClient` etc. in the widget (UI layer
  rule).

**Risk:** low. Pure presentation. No migration, no schema, no contract change.

---

### Phase 2 — Richer metadata (exercise count, optional "last trained")

**Goal:** stronger information scent — exercise count, and ideally "Last trained
{relative}", which is more useful to a lifter than "Edited".

This crosses the domain + persistence layers, so it needs a repo method and
tests. Read-only — **no schema bump**.

Changes:

1. **Domain contract**: add a read-only summary query to
   [ProgramRepository](mobile/lib/modules/domain/repositories/program_repository.dart),
   e.g.
   ```dart
   Future<List<ProgramSummary>> listProgramSummaries();
   ```
   where `ProgramSummary` is a small domain model: `program`, `dayCount`,
   `exerciseCount` (and, if doing last-trained, `lastTrainedAt`). Prefer a single
   aggregated COUNT query in the Drift impl over loading full
   `ProgramAggregate`s — keep the home screen's first paint cheap and
   offline-fast. (Counting via `listWorkoutDaysForProgram` per program is the
   fallback but is N queries; avoid if a `COUNT`/join is straightforward.)
2. **Persistence impl**: implement in the Drift `ProgramRepository`
   implementation; add tests to
   [drift_program_repository_test.dart](mobile/test/repository/drift_program_repository_test.dart)
   (counts for: 0 days, multiple days, supersets, warmups — mirror
   `WorkoutDaySummary.fromWorkoutDay`'s counting rules).
3. **Bloc/state**: `ProgramListBloc` calls `listProgramSummaries()` instead of
   `listPrograms()`; `ProgramListLoaded` carries `List<ProgramSummary>` (or a
   `List<ProgramListItemVm>`). Sort logic unchanged (by `updatedAt`).
   `ProgramListBloc` has **no existing test** today; add a plain unit test (no
   `bloc_test` — it is not a dependency, per [CLAUDE.md](CLAUDE.md)) covering
   load → summaries mapped, and delete flow still works.
4. **Tile**: extend the metadata row to `"{days} · {exercises} · Edited/Last
   trained {date}"`, with graceful truncation at large text scales.

**"Last trained" sub-option (heavier — gate behind user sign-off):** there is no
`listSessionsForProgram` today — only `listSessionsForWorkoutDay`
([session_repository.dart](mobile/lib/modules/domain/repositories/session_repository.dart)).
Computing last-trained per program needs either a new
`SessionRepository.lastCompletedByProgram()` query **and** injecting
`SessionRepository` into `ProgramListBloc`. Treat as its own slice; if it's not
cheap, ship Phase 2 with exercise count + "Edited" and defer "Last trained".

**Acceptance criteria**
- Tiles show accurate exercise counts matching the editor/picker counting rules.
- Home-screen load does a bounded, small number of queries (ideally one) — no
  per-program N+1 fan-out.
- New persistence tests pass; `ProgramListBloc` unit test passes.

**Risk:** medium. New contract method + impl + tests; bloc/state shape change.
Layering guard (`tool/check_offline_imports.sh`) must still pass — the new model
stays in `domain`, the count query stays in `persistence`.

---

### Phase 3 — Deferred / explicitly NOT building now

Listed so they're consciously rejected, not forgotten. Do not build without a
clear need (Hick's law; respect non-goals):

- Search / sort controls / tags / filters — overkill for a few programs.
- Undo-on-delete snackbar (note: undo was deliberately *removed* from set logging
  in commit `d0814c6`; match that team preference unless asked).
- Program duplication from the list.
- Reordering programs manually (the editor reorders *days*; programs sort by
  recency).
- Any streak/badge/"X workouts this week" surface — **violates non-goals.**

---

## 6. Consistency & token checklist (mandatory)

Per [CLAUDE.md](CLAUDE.md), everything under `screens|widgets/` must use tokens.
For each new/changed widget:

- [ ] Colors only via `Theme.of(context).appColors` — no `Color(0x…)`, no direct
      `AppColors.dark/light`.
- [ ] Spacing/radius via `AppSpacing` / `AppRadius` (accent bar width =
      `AppSpacing.xs`).
- [ ] Typography via `Theme.of(context).textTheme.*` / `AppTypography.standard`;
      counts are not "live numeric readouts" so `caption` is fine (no
      `numericLarge` needed here — that's a sweaty-hands-surface rule).
- [ ] Tap targets ≥ `AppSpacing.touchMin` (48 dp) — and **not** inflated to 56–64
      dp (this screen is outside `workout_overview/`+`focus_mode/`).
- [ ] Chips reuse the existing pill recipe (low-alpha fill + 0.5-alpha border +
      `badge` type) from `day_tile.dart` / `workout_day_list_tile.dart`.
- [ ] No `drift` / `AppDatabase` / `HttpClient` / `Socket` references in UI;
      cross-module imports through barrels with `package:zamaj/...`.

**Reuse opportunity:** the `IN PROGRESS` chip, the accent-bar wrapper, and the
skeleton bar are now duplicated across `day_tile.dart`,
`workout_day_list_tile.dart`, and (proposed) the program tile. Consider
extracting shared widgets into `lib/building_blocks/` (referenced by CLAUDE.md
but currently empty) — e.g. `StatusPill`, `ActiveAccentBar`, `SkeletonBar`. This
is optional polish, best done as a small follow-up refactor rather than blocking
Phase 1.

---

## 7. Decisions for the user

1. **Phase 1 only, or Phase 1 + Phase 2?** Phase 1 is high-value/low-risk and
   needs no data-layer work. Phase 2 adds exercise counts (and maybe "last
   trained") but touches the repo contract + tests.
2. **Leading anchor: program initial vs. a single dumbbell icon vs. none?**
   Recommendation: initial letter (best for differentiation). Easy to swap.
3. **"Last trained" vs. "Edited" in the metadata row.** "Last trained" is more
   useful but heavier (needs a session query + repo injection). OK to defer?
4. **Exercise library action — keep as a top-bar icon, or move to an overflow
   `⋮` menu?** Minor; default is to leave it as-is.

---

## 8. Testing & validation

- **Automated scope is domain + persistence only** ([CLAUDE.md](CLAUDE.md)): no
  widget tests, no goldens for this screen, no `bloc_test`.
  - Phase 1: no new automated tests (pure UI). Run `tool/ci.sh` (imports →
    codegen → format → analyze → test) to confirm layering + analyzer stay
    green.
  - Phase 2: add persistence tests for the new count/summary query and a plain
    unit test for `ProgramListBloc`.
- **Visual validation is the user's** (per saved preference). I will not launch
  the app to eyeball it; the user verifies the look on-device. The plan calls out
  text-scaling and the empty/in-progress/draft states as the things worth a quick
  manual look.

---

## 9. Impact on product-context.md

[product-context.md](product-context.md) describes Program list as "Browse /
create / delete programs. Entry point to the library and to text import." None of
the proposed changes add, remove, or rename a screen, feature, pillar, or
non-goal — they make the *same* screen clearer. **Phase 1 needs no
product-context update.** If Phase 2 adds a user-facing "Last trained" signal,
that's a small new at-a-glance capability worth a one-line mention in that screen's
bullet; revisit at that point.
