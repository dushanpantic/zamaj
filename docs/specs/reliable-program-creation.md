<!-- spec-version: 7.9.0 -->
**Format:** dev-team/specs 7.9.0

# Spec: Reliable program creation (name-first)

## Intent Description

Creating a new program is currently unreliable and can corrupt data. The program-name field auto-saves on **every keystroke**, and in create mode each save inserts a brand-new program row; because the editor bloc processes events concurrently and the create→edit flip only happens after a save resolves, typing a name like `ASDF` races several overlapping inserts and produces multiple partial programs (`A`, `AS`, `ASDF`). The resulting inconsistent editor state (`programId` / baseline days pointing at different rows) then throws an uncaught `StateError` on a subsequent edit or back action, crashing the app.

This change replaces silent per-keystroke creation with an explicit **name-first creation dialog**. The user names the program (required) *before* it exists; the program is written **exactly once**; and the editor only ever operates on an already-saved program. This eliminates the duplicate-program defect and the crash, and makes a non-empty program name mandatory at creation. Editor persistence is additionally hardened so that a save failure surfaces as a non-fatal error rather than an uncaught exception.

The intent is correctness and predictability of the creation flow only — it does **not** change how exercises, sets, or sessions work, and it does not forbid empty programs (no days) or empty days (no exercises); those remain valid, they just must never crash.

## Architecture Specification

**Components affected**

- **`program_list_screen.dart`** — the Programs app-bar `+` action and the empty-state "Create program" CTA open the new name-first creation dialog instead of pushing the editor in create mode. On a successful create, navigate to the editor in **edit mode** for the new `programId`. Tapping an existing program (including one with no days) still opens the editor unchanged.
- **New creation dialog** (`program_management/widgets/`) — a required-name field. The Create action is disabled until the trimmed name is non-empty and within `ProgramRules.programNameMaxLength` (100). Dismissing (Cancel / system back / scrim) with a non-empty typed name shows a "Discard new program?" confirmation; an empty field dismisses silently.
- **Creation persistence** — a single repository write that creates a named program with no days, through the existing `ProgramRepository` contract (`saveProgramAggregate` with an empty `workoutDays`, or an equivalent create). Exactly one program INSERT.
- **`program_editor_bloc.dart` / `program_editor_screen.dart`** — the editor is no longer entered in create mode from the UI; it always receives a non-null `programId` and loads in edit mode. The create-mode branch (`programId == null` / `_persistCreate`) must no longer be reachable as a creation path (delete or leave provably dormant — /plan decides).
- **Event ordering & robustness** — editor mutations must not interleave into inconsistent persistence. Serialize editor events (sequential transformer) or otherwise guarantee single-writer ordering. `_persist` must not let a non-`DomainError` (e.g. `StateError('Baseline not found')`) escape uncaught: any persistence failure is captured into `lastSaveError` state, never crashes.

**Constraints**

- UI talks to data only through the `ProgramRepository` contract — no Drift/`AppDatabase` in UI (offline-import guard).
- UI tokens mandatory in the new dialog: no hard-coded pixels or color literals; tap targets ≥ `AppSpacing.touchMin`.
- `PRODUCT.md` "Program list" / "Program editor" bullets updated to describe name-first creation (user-facing flow change).
- Tests live under `test/modules/program_management/**` as plain `flutter_test` (no `bloc_test`, no Flutter widget tests); creation/edit logic is covered at the bloc/service level with a `FakeProgramRepository`. Dialog widget behavior is verified by inspection.

## Acceptance Criteria

- **AC1 — No duplicates.** Creating a program named `ASDF` results in exactly **one** program named `ASDF`; no partial-name programs (`A`, `AS`, `ASD`) are ever created, regardless of typing speed. *Pass:* program count increases by exactly 1 and the new program's name equals the entered name.
- **AC2 — Name mandatory.** A program cannot be created with an empty or whitespace-only name. Create is disabled/blocked until the trimmed name is non-empty and ≤ 100 chars. *Pass:* invoking Create with an empty/whitespace name persists nothing.
- **AC3 — No crash.** Creating a program, adding an empty day, and navigating back completes to the program list with no uncaught exception. Any editor save failure surfaces as a non-fatal notice (`lastSaveError`), not a crash. *Pass:* the sequence raises no exception; a forced repository error yields `lastSaveError` rather than propagating.
- **AC4 — Single write path.** Program creation performs exactly one program INSERT, and the editor is never opened in create mode from the list — it always loads an existing program in edit mode (`isCreateMode == false`). *Pass:* exactly one create call is issued; the opened editor exposes edit affordances.
- **AC5 — Entry points.** Both the Programs `+` action and the empty-state CTA open the name-first creation dialog; after Create the editor opens for the newly created (named, empty) program; cancelling the dialog creates nothing and returns to the list.
- **AC6 — Confirm before leaving.** Dismissing the creation dialog with a non-empty typed name shows a "Discard new program?" confirmation; Discard closes the dialog and creates nothing, Keep editing returns with the typed name intact; an empty field dismisses with no prompt.
- **AC7 — Existing behavior preserved.** Renaming an existing program and managing its days continue to work and auto-save; editing an existing program never creates a duplicate; tapping an existing program with no days still opens the editor in edit mode.
- **AC8 — Docs.** `PRODUCT.md` program-management section reflects the name-first creation flow.

## Ambiguity Log

| Decision | Classification | Resolved By | Rationale / Answer |
|----------|---------------|-------------|-------------------|
| Shape of the new-program creation flow | `requires-stakeholder-input` | human | **Name-first dialog**: name entered (required) before the program exists; created once; editor opens in edit mode. |
| What happens when leaving an uncreated new program | `requires-stakeholder-input` | human | **Confirm before leaving.** Under name-first the only place an uncreated program exists is the creation dialog, so this is reconciled to the dialog: dismissing with a typed name prompts "Discard new program?"; an empty field dismisses silently. |
| Whether empty programs (no days) and empty days (no exercises) remain allowed | `inferable` | inference | Keep allowed. The user reported a crash, not a request to forbid emptiness; the domain (`validateAggregate`) deliberately permits both. Fix the crash, don't add a constraint. |
| How to guarantee a single writer / no interleave | `inferable` | inference | Serialize editor events and/or remove the reachable create-mode path. Name-first already removes concurrent create; sequential ordering is the simplest belt-and-suspenders. Either satisfies "exactly one write, no interleave". |
| `_persist` catching only `DomainError` | `inferable` | inference | Broaden so no save failure crashes; capture into `lastSaveError`. Standard defensive practice; the uncaught `StateError('Baseline not found')` is the proximate crash. |
| Retention of the editor's create-mode code | `inferable` | inference | May be deleted or left provably dormant; spec requires only that it is not reachable as a second creation path. |
| Max program-name length at creation | `inferable` | inference | Reuse `ProgramRules.programNameMaxLength` (100), consistent with edit mode. |

## Consistency Gate

- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts
- [x] No contradictions between artifacts
- [x] Every gap/ambiguity finding is logged — inferable with rationale or resolved by human

**Verdict: PASS** — all consistency-gate items satisfied; cleared for planning.
