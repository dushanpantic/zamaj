# Zamaj — MVP Product Design Document

## Product Vision

Zamaj is a mobile-first training execution app optimized for real gym workflows.

The app is designed around one core idea:

> Coach defines the plan. Zamaj executes it smoothly.

The app is NOT intended to be:

* a social fitness platform
* a calorie tracker
* a fitness encyclopedia
* an AI coach
* a bodybuilding content app

The app IS intended to be:

* a workout execution tool
* a workout logging tool
* a coach-athlete communication tool
* an adaptive session tracker

Primary UX goals:

* minimal friction during workouts
* interruption tolerance
* one-handed usage
* fast adaptations during training
* low cognitive load
* resilient to real gym chaos

Examples of real-world situations the app should handle gracefully:

* equipment occupied
* fatigue causing weight changes
* user replacing exercises due to pain
* app backgrounding during rest
* user manually logging workout later
* supersets and reordered exercises

---

# Domain Glossary

## UI Terminology

| Term             | Meaning                                          |
| ---------------- | ------------------------------------------------ |
| Program          | Current training block                           |
| Week             | One training week                                |
| Workout Day      | Reusable workout structure (Upper A, Lower B...) |
| Session          | One execution instance of a workout day          |
| Exercise         | Individual movement                              |
| Exercise Group   | Single exercise or superset                      |
| Set              | One performance unit                             |
| Measurement Type | How exercise performance is measured             |
| Planned          | Coach-defined target                             |
| Actual           | What user actually performed                     |
| Replacement      | Swapped exercise during session                  |
| Extra Work       | Additional unplanned work                        |
| Superset         | Grouped exercises performed together             |

## Internal Domain Terminology

| Term       | Meaning                                    |
| ---------- | ------------------------------------------ |
| Macrocycle | Long-term training period                  |
| Mesocycle  | Training block / Program                   |
| Microcycle | One week                                   |
| Template   | Planned structure                          |
| Snapshot   | Immutable copy of plan used during session |
| Execution  | Actual performed workout                   |

---

# Core Product Philosophy

## Planned vs Actual

Planned values and actual execution must always be tracked separately.

Example:

Planned:

* Bench Press
* 100kg 4 × 8

Actual:

* 100 × 8
* 97.5 × 8
* 95 × 7
* 95 × 6

This distinction is critical for:

* progression tracking
* coach review
* export clarity
* preserving historical accuracy

---

# Program Structure

A Program consists of multiple Workout Days.

Example:

* Upper A
* Lower A
* Upper B
* Lower B

Programs evolve over time.

Coach will:

* review results
* modify weights/reps/sets
* create next version of the program

Because programs evolve:

* sessions MUST preserve snapshots of original planned values
* historical sessions must never change retroactively

---

# High-Level User Flow

1. Coach sends training plan
2. User creates/imports program
3. User selects Workout Day
4. User executes/adapts session
5. User exports session results
6. Coach adjusts next version of program

---

# Core Screens

## 1. Program Creation / Import Screen

Purpose:

* create or edit Program
* define Workout Days
* import coach-provided text plans

Primary workflow should optimize for:

* paste → parse → cleanup

NOT:

* manually filling giant forms

---

## Supported Features

### Create Program

* create Program name
* define Workout Days
* define exercises
* define planned sets/reps/weights/rest

### Import Program

User pastes text such as:

Upper A

Bench Press
4x8 100kg 2m

Incline DB Press
3x10 30kg

SS:
Cable Fly
Lateral Raise

App parses structure into editable preview.

### Measurement Types

Initial MVP supports:

* rep-based exercises
* time-based exercises

Examples:

Rep-based:

* Bench Press
* Squat
* Pullups

Time-based:

* Handstand Hold
* Plank
* Dead Hang

Planned format examples:

* 100kg 4 × 8
* 4 × 30s
* 20kg 3 × 45s

Actual execution examples:

* 100 × 8
* 97.5 × 8
* 35s
* 28s

Architecture should support additional measurement types later.

### Exercise Metadata

Exercises may optionally include:

* notes
* video links

Video links:

* open externally in YouTube
* never embedded inline
* accessible via context menu

### Exercise Groups

Initial MVP supports:

* single exercise
* superset

Architecture must support future types:

* dropset
* pyramid
* reverse pyramid
* circuit
* timed work

---

# 2. Workout Day Picker Screen

Purpose:

* select which Workout Day to execute today

Examples:

* Upper A
* Lower A
* Push
* Pull

Requirements:

* no strict calendar scheduling
* manual day selection
* show recent completion info
* show session history summary

Example:

Upper A
Last completed: Tuesday

Lower A
Not completed this week

---

# 3. Workout Overview Screen

This is the flexible workout workspace.

Purpose:

* inspect workout
* manage workout structure
* recover from interruptions
* manually log workouts
* reorder unfinished exercises
* create/remove supersets
* review progress

This screen should feel:

* compact
* scrollable
* editable
* informative

NOT immersive.

---

## Overview Screen Features

### Exercise Expansion

Tapping exercise expands inline.

Example:

Bench Press

✓ 100 × 8
✓ 97.5 × 8
○ 95 × 7
○ 95 × 6

Expanded section may show:

* sets
* notes
* last performance
* video links
* replacement info

---

## Reordering

Only unfinished exercises may be reordered.

Completed exercises:

* locked in chronological order
* still editable
* cannot be moved/grouped

Interaction:

* long press drag
* no explicit edit mode
* no save button

---

## Superset Creation

User creates supersets by dragging one exercise onto another.

Example:

Superset A
├ Incline DB Press
└ Cable Fly

Requirements:

* visually grouped
* flat structure only
* no nested groups

Ungrouping available through context menu.

---

## Manual Workout Logging

User must be able to enter completed workout after training.

Example use case:

* phone battery died
* user trained without app
* user logs later from memory

Overview mode supports:

* manual set entry
* manual completion
* adding notes
* adding extra work

---

## Extra Work

User may add additional unplanned work.

Initial MVP implementation:

* freeform text notes

Example:

* "3 calf sets"
* "extra abs"

---

## Exercise States

Exercise may be:

* unfinished
* completed
* skipped
* replaced

These states are semantically distinct.

---

## Exercise Replacement

Example:

* Bench Press causes shoulder pain
* user replaces with Cable Fly

Requirements:

* replacement affects current session only
* template remains unchanged
* preserve planned exercise reference

Example:

Planned:
Bench Press

Performed:
Cable Fly

---

## Session Notes

User should be able to attach quick notes.

Examples:

* "left shoulder pain"
* "machine occupied"
* "felt strong"

---

# 4. Focus Mode Screen

This is the workout execution engine.

Purpose:

* guide current set execution
* minimize cognitive load
* maintain workout momentum

Focus mode should feel:

* calm
* obvious
* minimal
* persistent

---

## Focus Mode Navigation

Opening Focus Mode always resumes at:

* next unfinished set
* next unfinished exercise

Example:

Bench Press
✓ Set 1
✓ Set 2
✓ Set 3
○ Set 4

Entering focus mode opens directly to Set 4.

---

## Focus Mode Layout

Focus mode UI adapts dynamically based on exercise measurement type.

### Rep-Based Example

Recommended structure:

Exercise Name

Planned
100kg 4 × 8

Last Set
97.5 × 8

Current
[95] × [7]

[-2.5] [+2.5]
[-1] [+1]

[ COMPLETE SET ]

Rest Timer
01:32

Up Next
Incline DB Press

### Time-Based Example

Exercise Name

Planned
4 × 30s

Current
[32s]

[ START TIMER ]

[ STOP ]

Rest Timer
01:32

Up Next
Plank Hold

---

## Set Editing UX

### Planned Values

Always visible and immutable during execution.

### Actual Values

Editable per set.

Every set is independently editable.

Actual values initialize from:

* previous actual set
* NOT always planned values

---

## Increment Rules

### Weight

If current weight:

* ≤ 10 → ±1
* > 10 → ±2.5

Manual numeric input must always be available.

### Reps

* ±1 buttons
* manual input available

### Duration

* timer-based input supported
* manual duration input supported

---

## Set Completion

Primary action:

[ COMPLETE SET ]

Pressing button:

* logs set
* advances workout flow
* starts timer automatically

No confirmation dialog.

Optional temporary Undo action may appear.

---

## Rest Timer

Rest timer behavior:

* automatic start after set completion
* automatic progression handling
* supports pause/skip/+15 sec

Track BOTH:

* planned rest
* actual rest

Actual rest should be calculated passively via timestamps.

---

## Background Survival

Workout session must survive:

* app backgrounding
* phone locking
* app switching
* YouTube/music usage

Session state should persist continuously.

---

## Timer Persistence

Android implementation should eventually support:

* foreground notification timer
* lockscreen visibility
* timer controls from notification

Possible actions:

* skip rest
* +15 sec
* pause

---

## Up Next Section

Focus mode should provide lightweight future visibility.

Only show:

* next set
* next exercise

Avoid showing entire workout.

---

# Session Model

Sessions are runtime execution instances.

Sessions preserve:

* template snapshot
* actual execution
* replacements
* skipped exercises
* reordered exercises
* extra work
* notes

Session history is immutable historical truth.

---

# Session Rules

## Mutable

* unfinished exercises
* draft values
* exercise order before completion
* supersets before completion

## Locked

* completed exercise ordering
* historical snapshots

## Editable After Completion

* reps
* weight
* notes

Editing completed values:

* updates statistics/history
* does NOT reopen workout flow
* does NOT restart timers

---

# Planned vs Actual Visualization

The app should visually distinguish:

* planned values
* actual values

But deviations should NOT feel like errors.

Training adaptation is normal.

Visual distinction should be subtle.

---

# Export Features

## Export Workout Day

Export completed session as text.

Primary use case:

* sending to coach via WhatsApp

Example format:

Upper A

Bench Press
Plan: 100kg 4 × 8
Done:
100 × 8
97.5 × 8
95 × 7
95 × 6

Incline DB Press
30 × 10
30 × 10
28 × 9

Notes:
Left shoulder discomfort

---

## Export Week

Export all completed sessions for one week.

Example:

Week 4

Upper A
...

Lower A
...

Upper B
...

Initial implementation:

* plain text only
* optimized for WhatsApp sharing

---

# Non-Goals For MVP

The MVP should NOT include:

* backend sync
* accounts/auth
* social features
* AI coaching
* nutrition tracking
* embedded videos
* wearable integrations
* advanced analytics dashboards
* calendar scheduling
* PR celebrations/gamification

---

# Technical Principles

## Offline First

All data stored locally on device.

## Persistent Session State

Persist after:

* set completion
* timer updates
* edits
* replacements
* reorder operations

## Architecture Separation

Strongly separate:

### Templates

Planned coach structure

### Sessions

Actual workout execution

### Flow Engine

Workout progression logic

### UI Layer

Interaction + presentation

---

# Future Considerations

Potential future support:

* dropsets
* pyramids
* reverse pyramids
* RPE/RIR
* deload weeks
* wearable integration
* cloud sync
* coach portal
* advanced analytics
* voice notes
* plate calculator
* exercise substitution recommendations
* import from spreadsheets/docs

These should NOT complicate MVP UX.
