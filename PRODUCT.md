# Product context — Zamaj

## What it is

A Flutter workout-execution app. Currently single-user (built for the maintainer); positioned to go public if it earns its keep against existing tracker apps. Architecture and conventions live in [CLAUDE.md](CLAUDE.md); this doc is the **why and what**.

## Who it's for

A solo lifter following a structured strength program who logs every set on a sweaty phone in the gym and wants the record to reflect *both* what was planned and what actually happened.

## Two pillars

1. **Planned vs. actual are first-class.** Every set carries its planned target (weight × reps, time, bodyweight reps, etc.) and a separately-tracked actual value; the UI never collapses one into the other. This is what enables honest retros, deload decisions, and the per-exercise progress trend.
2. **Sweaty-hands ergonomics in-session.** The two live-session surfaces (workout overview and focus mode) are tuned for wet hands and quick taps between sets, so a set logs in one confident tap. Outside the gym (program editing, settings) standard tap targets are fine. The dp spec and its exceptions live in CLAUDE.md.

## How a session works

Starting a session takes a **snapshot** — the planned workout day frozen at that moment. The program template can keep evolving afterwards; this session's plan does not. A completed session is meant to read as a faithful record of "the plan I was on, and what I did against it."

One narrow softening of that immutability: you may correct a mis-logged **actual** value on a session from the current week — values only, never adding or removing sets, and never touching the frozen plan snapshot. Older sessions are read-only.

A session can be started as a **deload**: each working exercise's planned set count is halved (rounded up; warmups untouched) in the snapshot, so logging the lighter quota still reads as *completed*, not partial. Weight cuts stay manual. A deload is tagged for life — surfaced wherever the session appears, marked in export, and held out of the progress trend and the CAPPED computation so a deliberately easy week never reads as a regression or a maxed lift. The program template is never changed.

## Key concepts

- **Completed / partial / skipped** is *derived from what you logged, never declared* — there is no "mark it done" button. An exercise **auto-completes** once you've logged its planned number of sets; stop it short and it reads **partial** ("2/4 sets") if some sets are in, **skipped** if none. Every read surface (live card, session review, history tile, export) computes this from logged-vs-planned counts, so a ✓ never editorializes over partial work.
- **Superset** lives in two places by design: you build one in the day editor (movements done back-to-back), and you run it in a session as a group. Each is independent — editing the plan's grouping never rewrites a session already underway, because the session carries its own grouping frozen in the snapshot.
- **CAPPED** flags a linked exercise whose most recent session at the current weight + target hit every working set — a descriptive marker that the lift is maxed at its current prescription and hasn't been advanced. Warmup-group and unlinked exercises are never flagged.
- **Top set** is the heaviest weighted set logged for an exercise; it's the basis of the per-exercise progress trend.

## Features by screen

The app opens into a two-tab shell — **Programs** and **Library** — launching on Programs; each tab keeps its own state. Detail screens and live sessions present *over* the shell, so the bottom bar is absent in-session.

### Program management — [program_management/](mobile/lib/modules/program_management/)
- **Program list** (the Programs tab) — browse, create, and delete programs; entry point to text import.
- **Program editor** — rename a program and manage its workout days.
- **Workout-day editor** — order and group exercises into supersets; add from the library or as a one-off. Linked exercises show the **CAPPED** flag.
- **Exercise editor** — name, measurement type, planned sets, rest, notes, video, optional library link. Identical sets edit as one (a single weight / reps / set-count with ± steppers drives every set); **Vary by set** drops to per-set rows for pyramids and drop sets. A **Recent history** section lists the last five completed sessions of a linked movement (across every program it appears in) — date, planned target, per-set actuals, with a `▲` when that session capped its target.
- **Plan import** — paste a coach's plan as plain text, parse it into a structured program, preview before saving.

### Exercise library — [exercise_library/](mobile/lib/modules/exercise_library/)
Ships **pre-populated** with a curated catalog (~80 movements), each tagged with its target muscles and a prominence tier. Durable identity means the same movement on different days or programs is one entry — the prerequisite for cross-session progress aggregation. You can still add, rename, archive, and link your own entries; the catalog re-seeds on every launch without duplicating rows or clobbering your edits.
- **List** (the Library tab) — search, filter active/archived, manage entries; common movements first, then specialized, alphabetical within each tier.
- **Editor** — name, measurement type (locked after first save), video, cues, archive/unarchive.
- **Link suggestions** — bulk-link program exercises that match a library entry by normalised name, keeping your own local name; programs, set data, and session history are untouched.

### Starting a session — [workout_day_picker/](mobile/lib/modules/workout_day_picker/)
- **Workout-day picker** — choose which day to do today. A **Deload week** toggle (off by default) starts the chosen day as a deload. Only one session runs at a time: while any session is in progress, a banner offers to resume it and the other days' start actions recede, so resume is the one available action. This single-active-session rule is enforced only here, in the UI.

### In-session (sweaty-hands) — [workout_overview/](mobile/lib/modules/workout_overview/), [focus_mode/](mobile/lib/modules/focus_mode/)
- **Workout overview** — the full session: every exercise expands to its set list, where the active set logs in one tap (with undo) or via an inline editor when the value differs from plan. From here you can reorder exercises, form and ungroup supersets, remove a single exercise from a superset, end/skip/resume a movement, log an extra set beyond plan, add an unplanned exercise, or replace one. All structural edits act on the live session only — the frozen plan snapshot is never touched, and extra or unplanned work is recorded as actual work outside the plan. Replace and End/Skip resolve a movement to its terminal completed/partial/skipped state; there is no separate "replaced" badge. After the session ends, new logs and structural changes lock, but already-logged actuals stay correctable, and a summary card heads the screen (time, working sets done vs planned, total weighted volume).
- **Focus mode** — one exercise (or one superset group) at a time: large LOG SET button, a rest timer that auto-dismisses at zero, undo last set, partner cards for superset members. Optimised for between-set use.

### After a session — [export/](mobile/lib/modules/export/)
- **Recent sessions** — completed sessions bucketed into "This week" and "Earlier", with a one-tap export-this-week action. Tap a session to open its review.
- **Session detail (review)** — a summary card (time, working sets done vs planned, total weighted volume), then the frozen plan beside what was actually logged, set by set, each exercise marked completed / partial / skipped, supersets grouped, plus notes and extra work. A current-week session allows correcting a mis-logged actual (values only); older sessions are read-only. Per-session plain-text export lives here; each exercise card also opens that exercise's progress trend.

### Exercise progress — [exercise_progress/](mobile/lib/modules/exercise_progress/)
- **Exercise progress (top-set trend)** — a per-exercise line chart of the top set over time, aggregated across **every program** the exercise has appeared in, so one library movement reads as a single trend even as it moves between programs. Reachable from the Library editor and a finished session's exercise card. Weighted (weight × reps) exercises only — time-based, bodyweight, and exercises not linked to a library entry show an explanatory empty state. Computed live from local session history, so a deleted session drops out of the trend.

## Explicit non-goals
- **No social, streaks, badges, friends, or leaderboards.** This is a logbook, not a community app.
- **No cloud sync, accounts, or server today.** Data lives in local SQLite. May change if the app grows a "coach edits my plan remotely" use case — currently out of scope because there's no second user.
- **No coaching / AI recommendations.** The app records what you do; it does not tell you what to lift.
