# Product context — Zamaj

## What it is

A Flutter workout-execution app. Currently single-user (built for the maintainer); positioned to go public if it earns its keep against existing tracker apps. Architecture details live in [CLAUDE.md](CLAUDE.md); this doc is the **why and what**.

## Who it's for

A solo lifter following a structured strength program — squats, bench, accessory work — who logs every set on a sweaty phone in the gym and wants the record to reflect *both* what was planned and what actually happened.

## Two pillars

1. **Planned vs. actual are first-class.** Every set carries its planned target (weight × reps, time, bodyweight reps, etc.) and a separately-tracked actual value. The UI never collapses one into the other. This is what enables honest retros, deload decisions, and the per-exercise progress trend.
2. **Sweaty-hands ergonomics in-session.** The two live-session surfaces ([workout_overview/](mobile/lib/modules/workout_overview/), [focus_mode/](mobile/lib/modules/focus_mode/)) are tuned for wet hands and quick taps between sets: 64 dp counter buttons, 36 px numeric readouts, ≥56 dp primary actions. Outside the gym (program editing, settings) the standard 48 dp tap target is fine.

## How a session works

Starting a session takes a **snapshot** of the planned workout day at that moment. The program template can keep evolving afterwards, but this session's plan is frozen at start. Completed sessions are meant to read as a faithful record of "the plan I was on, and what I did against it". A deliberate, narrow softening of strict immutability lets you correct a mis-logged **actual** value on a session from the current week — values only, never adding or removing sets, and never touching the frozen plan snapshot.

## Two words worth pinning down

- **Superset** lives in two places by design. You build one in the day editor (movements done back-to-back), and you then run it in a session as a group focus mode steps through as partner cards. Each is independent: editing the plan's grouping never rewrites a session already underway, because the session carries its own grouping frozen in the snapshot.
- **Completed** (for an exercise) is *derived from what you logged, never declared* — there's no "mark it done" button. An exercise **auto-completes** once you've logged its planned number of sets. Stop it short with the single adaptive action — **End exercise** once some sets are in (keeping what you logged), **Skip exercise** with none — and it reads as **partial** ("2/4 sets") or **skipped** respectively. Every read surface (live card, session review, history tile, plain-text export) computes completed / partial / skipped from the logged-vs-planned set counts, so a ✓ never editorializes over partial work.

## Features by screen

The app opens into a two-tab bottom-navigation shell — **Programs** and **Library** — launching on the Programs tab. Each tab keeps its own state as you switch. Detail screens and live sessions present *over* the shell, so the bottom bar is absent in-session.

### Program management — [program_management/](mobile/lib/modules/program_management/)
- **Program list** — [program_list_screen.dart](mobile/lib/modules/program_management/screens/program_list_screen.dart). The Programs tab. Browse / create / delete programs. Entry point to text import.
- **Program editor** — [program_editor_screen.dart](mobile/lib/modules/program_management/screens/program_editor_screen.dart). Rename a program, manage its workout days.
- **Workout-day editor** — [workout_day_editor_screen.dart](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart). Order and group exercises (supersets); add via library picker or as a one-off. A linked exercise carries a **CAPPED** badge when its most recent session at the current weight + target hit every working set — a descriptive flag that the lift is maxed at its current prescription and hasn't been advanced. Warmup-group and unlinked exercises are never flagged.
- **Exercise editor** — [exercise_editor_screen.dart](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart). Name, measurement type, planned sets, rest, notes, video URL, optional link to a library entry. Identical sets edit as one: a single weight / reps / set-count with ± steppers drives every set at once (so a coach's "+2.5 kg" is one tap), while **Vary by set** drops to per-set rows for pyramids and drop sets — sets that already differ open there automatically. A **Recent history** section lists the last five completed sessions of a linked movement (across every program it appears in) — each row showing the date, planned target, and per-set actuals, with a `▲` marker when the session capped its target. Unlinked exercises show a nudge to link a library entry; linked-but-never-logged ones show an empty state.
- **Plan import** — [plan_import_screen.dart](mobile/lib/modules/program_management/screens/plan_import_screen.dart) → [plan_preview_screen.dart](mobile/lib/modules/program_management/screens/plan_preview_screen.dart). Paste a coach's plan as plain text, parse it into a structured program, preview before saving.

### Exercise library — [exercise_library/](mobile/lib/modules/exercise_library/)
Ships **pre-populated** with a curated canonical catalog (~80 common and specialized movements), each tagged with its target muscles (primary/secondary) and a prominence tier. Durable identity means the same "BB Bench Press" on PUSH day and UPPER day point to one entry — the prerequisite for cross-session progress aggregation. You can still add, rename, archive, and link your own entries; the catalog re-seeds on every launch without duplicating rows or clobbering your edits to a seeded entry.
- **List** — [exercise_library_list_screen.dart](mobile/lib/modules/exercise_library/screens/exercise_library_list_screen.dart). The Library tab. Search, filter active/archived, manage entries. Ordered common movements first, then specialized, alphabetical within each tier.
- **Editor** — [exercise_library_editor_screen.dart](mobile/lib/modules/exercise_library/screens/exercise_library_editor_screen.dart). Name, measurement type (locked after first save), video, cues, archive/unarchive.
- **Link suggestions** — [link_suggestion_screen.dart](mobile/lib/modules/exercise_library/screens/link_suggestion_screen.dart). Bulk-link existing program exercises that match by normalised name. When the catalog was first introduced the library was reset, so program exercises start unlinked — re-link them here (keeping your own local name, e.g. "BB Bench" linked to "Barbell Bench Press"); programs, set data, and session history are untouched.

### Starting a session — [workout_day_picker/](mobile/lib/modules/workout_day_picker/)
- **Workout-day picker** — [workout_day_picker_screen.dart](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart). Choose which day of the program to do today. Only one session runs at a time: while any session is in progress (this program or another), a top banner offers to resume it and the other days recede with their start action removed, so resume is the one available action.

### In-session (sweaty-hands)
- **Workout overview** — [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart). The full session: every exercise card expands to its set list, where the active set logs in one tap on its circle (recording the suggested value, with an UNDO snackbar) or opens an inline ± editor to log a value that differs from plan; drag-to-reorder between cards, drag-onto-card (or a partner-picker sheet) to form a superset, ungroup, end or skip an exercise (one adaptive action — Skip when nothing's logged, End when some sets are), session notes, extra work, end session. Once a session is ended the screen locks new logs and structural changes, but already-logged set values stay editable so a mis-logged number can still be corrected; a summary card then heads the screen with the session's time, working sets done vs planned, and total weighted volume. The note, extra-work, and group-with-partner flows each open as a bottom sheet.
- **Focus mode** — [focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart). One exercise (or one superset group) at a time. Large LOG SET button, a rest timer that auto-dismisses at zero (with a haptic), undo last set, partner cards for superset members. Optimised for between-set use.

### After a session — [export/](mobile/lib/modules/export/)
- **Recent sessions** — [recent_sessions_screen.dart](mobile/lib/modules/export/screens/recent_sessions_screen.dart). Completed sessions bucketed into "This week" and "Earlier", with a one-tap "export this week" action. Tapping a session opens its review.
- **Session detail (review)** — [session_detail_screen.dart](mobile/lib/modules/export/screens/session_detail_screen.dart). Review of a finished session: a summary card at the top (time, working sets done vs planned, total weighted volume), then the frozen plan beside what was actually logged, set by set, with each exercise marked completed / partial / skipped / replaced (derived from its logged sets), supersets grouped, and the session's notes and extra work. For a session from the current week, tapping a logged value opens an editor to correct a mis-logged actual (values only — the plan snapshot stays frozen); older sessions stay read-only. Per-session plain-text export lives here, behind the app-bar share icon. Each exercise card also opens that exercise's progress trend.

### Exercise progress — [exercise_progress/](mobile/lib/modules/exercise_progress/)
- **Exercise progress (top-set trend)** — [exercise_progress_screen.dart](mobile/lib/modules/exercise_progress/screens/exercise_progress_screen.dart). A per-exercise line chart of the **top set** (heaviest weighted set) logged over time, aggregated across **every program** the exercise has appeared in, so one library movement reads as a single trend even as it moves between programs. Reachable from the Library editor and from a finished session's exercise card. Weighted (weight × reps) exercises only — time-based, bodyweight, and exercises not linked to a Library entry show an explanatory empty state instead. Exactly one logged session shows a single top-set stat; none shows a "no sessions yet" prompt. Tapping a point names the workout day it came from. Computed live from local session history, so a deleted session drops out of the trend.

## Explicit non-goals
- **No social, streaks, badges, friends, or leaderboards.** This is a logbook, not a community app.
- **No cloud sync, accounts, or server today.** Data lives in local SQLite. May change if the app grows a "coach edits my plan remotely" use case — currently out of scope because there's no second user.
- **No coaching / AI recommendations.** The app records what you do; it does not tell you what to lift.
