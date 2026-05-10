# Product

**Zamaj** is an offline-first mobile workout execution app built with Flutter. It is a tool for executing and logging coach-defined training plans — not a social platform, tracker, or AI coach.

## Core idea

> Coach defines the plan. Zamaj executes it smoothly.

## What it is

- Workout execution tool
- Workout logging tool
- Coach-athlete communication tool (via text export)
- Adaptive session tracker

## What it is not

- Social fitness platform
- Calorie/nutrition tracker
- Fitness encyclopedia
- AI coach
- Bodybuilding content app

## Primary UX goals

- Minimal friction during workouts
- Interruption tolerance (backgrounding, lock screen, phone off)
- One-handed usage
- Fast in-session adaptations (exercise replacement, supersets, reorder)
- Low cognitive load
- Resilient to real gym chaos (occupied equipment, fatigue, pain)

## Core domain concepts

- **Program** — a training block made of **Workout Days** (e.g. Upper A, Lower B).
- **Session** — one execution of a Workout Day. Captures an immutable **snapshot** of the planned structure plus the actual execution.
- **Planned vs Actual** — always tracked separately. Planned values are coach intent; actual values are what the user performed. Deviations are normal, not errors.
- **Exercise Group** — a single exercise or a superset. Architecture must allow future kinds (dropset, pyramid, circuit).
- **Measurement Type** — currently rep-based and time-based. Extensible.
- **Exercise State** — unfinished, completed, skipped, or replaced.

## Non-negotiable principles

- **Offline first.** All data lives on the device. The `core`, `domain`, and `persistence` layers must not import any networking package.
- **Historical immutability.** Completed sessions preserve snapshots of original planned values and never change retroactively when a program evolves.
- **Template integrity.** In-session replacements affect only the current session; the program template is not mutated.

## MVP non-goals

Backend sync, accounts, social, AI coaching, nutrition, embedded video, wearables, analytics dashboards, calendar scheduling, gamification.

See `mvp-design-doc.md` at the repo root for the full product brief.
