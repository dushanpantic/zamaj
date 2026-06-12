# Domain Refactor — pushing business logic down to `domain/`

Analysis date: 2026-06-11. Scope: `mobile/lib/`. Method: DDD strategic/tactical review plus a ubiquitous-language pass (glossary written to `.plans/domain/`, one file per concept).

## Overall shape

The architecture is in good health: `domain/` is pure Dart, layer isolation is enforced by `tool/check_offline_imports.sh`, the snapshot/immutability pillar is modeled explicitly, and value objects (`RepTarget`, `PlannedSetValues`, `ActualSetValues`, `SessionSnapshot`) validate themselves in constructors. The findings below are not about broken layering — they are about **business rules that ended up above or below the domain layer**, in three recurring patterns:

1. **The "smart repository" pattern.** `SessionRepository` is not a persistence port; it *implements* domain transitions. `SessionFlowEngine` validates preconditions, then delegates the actual state change to Drift code. The most important rules of the app live in SQL-adjacent code.
2. **Domain policies stranded in feature modules.** Week windows, editability, rotation policy, link clustering — pure-Dart rules with no Flutter dependency, sitting under `lib/modules/<feature>/services/`, in two cases imported *across* sibling UI modules.
3. **The "effective exercise" projection re-implemented five times.** Resolving a `SessionExercise` against its snapshot (planned exercise, measurement type, set count, display name, group role) is private logic in the engine, the Drift repo, two assemblers, and a bloc — with three behavioral divergences already.

Findings are ordered by priority. Each lists the rule, where it lives, why it belongs in domain, and a suggested landing spot.

---

## Decision log (2026-06-11 interrogation)

Every finding was reviewed with the owner. Statuses below are binding for the implementation plan; the **Agreed implementation scope** section at the end of this document is the direct input for `/plan`.

| Finding | Decision | Resolution |
| --- | --- | --- |
| 1, 4, 12 | **In scope** | Pure domain functions (`ExerciseStateTransitions`, `SupersetOrdering`, `SessionSeed`) that the Drift repo calls **inside its existing transactions**. The repo keeps its in-transaction re-reads (the race protection); only the decision logic moves. Do NOT move computation up into the engine — that would require an optimistic-concurrency redesign. |
| 2 | **Resolved — keep as-is** | Single-active-session stays a UI-only rule by design (future coach+trainee model may need concurrent sessions). |
| 3, 10 | **In scope** | Move all three to domain: `CurrentWeekWindow` → `domain/models/` renamed **`TrainingWeek`**, `SessionEditability` → domain policy, history derivations → domain `SessionHistory` service. Monday week-start stays hardcoded (product fact, not a preference). |
| 5 | **DEFERRED — do not touch** | No contiguity enforcement in the engine. Reason: the only current way to pull one exercise out of a superset is disbanding the whole group (bad UX); a future interaction may *intentionally* split a run. Revisit with the superset UX redesign. |
| 6 | **In scope** | Indexed resolver: `EffectiveExercises.of(session)` in domain (builds the snapshot index once; exposes effective measurement type, planned set count, display name, group role, planned exercise per session-exercise). Missing planned exercise **always throws** `NotFoundError` — this deliberately replaces the repo's silent set-count-0 behavior. Add `ActualSetValues.matches(MeasurementType)` on the value object. Engine, repo, both assemblers, and the focus bloc's `_matches` all migrate to it. |
| 7 | **In scope** | Domain `ProgramRules` (bound constants + validation) enforced at the **write path** (AggregateSaver / repository save), not in model constructors — legacy rows must keep loading. `ProgramValidation` (UI) delegates to it for messages. `parseRepTarget` moves to domain as `RepTarget.parse`. Program-name limit unified at **100 chars everywhere** (the 120-on-create was unintended). |
| 8 | **In scope** | Canonical rule: **most recently worked on** — `updatedAt` desc, then `startedAt`, then id — as a domain `ActiveSessionPolicy`. The summarizer's `_beats` delegates to it; the repo's `getActiveSession`/`watchActiveSession` `ORDER BY` changes from `startedAt` to match. |
| 9 | **Opportunistic** | Rotation/progression policy moves to domain when focus-mode (or the Replace redesign) is next touched. Not in this batch. |
| 11 | **Split** | `LinkSuggester` moves to `domain/services/` **now** (pure move, only domain types). The apply-cluster use case (`ExerciseLinkingService` + transactional bulk link) is opportunistic — when the library feature is next touched. |
| 13 | **Not in batch** | `IncrementRules` stays in `core/` for now; pure relocation with no behavioral value. |
| 14 | **In scope** | Summary-formatter overload for `(PlannedSetValues, setCount)`; delete `FocusModeAssembler._summarizeSubstitute`. |
| 15 | **In scope** | `ExerciseGroupKind.forMemberCount(int)` in domain; editor draft and group validation both use it. |
| 16 | **Deferred** | Set-row pairing extraction waits until per-set exports need it. |

---

## P1 — Core invariants and transitions outside the domain

### 1. Exercise auto-complete / revert transitions live only in the Drift repository

- **Where:** [drift_session_repository.dart:398-411](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L398-L411) (`completeSet`), [drift_session_repository.dart:550-563](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L550-L563) (`deleteExecutedSet`)
- **The rules:**
  - Logging the set that meets the planned quota flips an `unfinished` exercise to `completed` (and only from `unfinished` — `replaced` stays `replaced`).
  - Deleting a set that drops the count below quota flips `completed` back to `unfinished`.
- **Why this is domain:** these are *the* central lifecycle rules of workout execution. The engine's doc comments describe them, but the implementation — including the subtle "only from `unfinished`" guard — exists nowhere in `domain/`. A second repository implementation (export/import, sync, test fake) must re-derive them from the Drift code.
- **Suggestion:** extract a pure domain function, e.g. `ExerciseStateTransitions.afterSetLogged(currentState, executedCount, plannedCount) → ExerciseState` and `afterSetDeleted(...)` in `domain/services/`, called by the repository (short term) or by the engine itself with the repo reduced to persisting the computed state (long term). The existing Drift integration tests in `test/integration/` already pin the behavior, so the extraction is low-risk.

### 2. Single-active-session rule — RESOLVED: deliberately UI-only, keep as-is

- **Where:** [workout_day_picker_bloc.dart:153-157](mobile/lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart#L153-L157) — `if (current.activeSession != null) return;` with the comment "Only one session may run at a time".
- **Decision (2026-06-11):** the engine intentionally permits concurrent sessions. "One session at a time" is a *current-product* UI rule, not a domain invariant — the domain stays open for a possible coach+trainee model where a coach runs multiple trainees' sessions in parallel. Do not push this into `SessionFlowEngine`.
- **Residual implication:** finding 8 (two competing "active session" definitions) becomes *more* important in that future, since "active" will need a per-trainee qualifier; settling on one selection policy now keeps that door clean.

### 3. Session editability policy + the training-week concept live in (and across) UI modules

- **Where:** [session_editability.dart](mobile/lib/modules/export/services/session_editability.dart) (export module), [current_week_window.dart](mobile/lib/modules/workout_day_picker/services/current_week_window.dart) (day-picker module), imported by `export/services/session_history_assembler.dart`, `export/bloc/recent_sessions_bloc.dart`, and `export/bloc/session_detail_bloc.dart`.
- **The rules:**
  - `TrainingWeek` (code: `CurrentWeekWindow`): the Mon–Sun local-time week that defines "this week" everywhere.
  - `SessionEditability`: an ended session's *actual* values stay correctable only inside the current week — the one deliberate softening of session immutability, tied to the coach-report deadline.
- **Why this is domain:** the editability rule is the counterpart of the immutability pillar in CLAUDE.md — it modifies the aggregate's core invariant, and it currently lives two modules away from the invariant it softens. `CurrentWeekWindow` is a pure value object that three modules need; the **export module currently imports from `workout_day_picker/`**, a sibling-feature dependency that the barrel-file convention papers over.
- **Suggestion:** move `CurrentWeekWindow` to `domain/models/` (glossary proposes the name `TrainingWeek`) and `SessionEditability.canEditValues` to a domain policy beside it. The day-picker, export, and history code all consume it from `domain.dart`. This also removes the only cross-feature UI import found in the scan.

### 4. Superset re-blocking and insertion order are computed in persistence

- **Where:** [drift_session_repository.dart:861-879](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L861-L879) (`createSuperset`: pull members into a contiguous block anchored at the earliest member), [drift_session_repository.dart:1001-1013](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L1001-L1013) (`addToSuperset`: re-insert dragged exercise immediately after the last member).
- **Why this is domain:** which exercise ends up where is a business decision (it defines what the lifter sees and what `groupBySupersetRun` derives), expressed as pure list manipulation — it has nothing to do with SQLite. The two-phase UNIQUE-dodging writes are genuinely persistence concerns and should stay; the *order computation* should not.
- **Suggestion:** domain functions, e.g. `SupersetOrdering.blockedOrderForCreate(allIds, chosenIds)` and `orderForAppend(unfinishedIds, memberIds, draggedId)` in `domain/` (next to `superset_grouping.dart`), unit-tested in pure Dart; the repo maps the returned order onto position slots.

### 5. Superset contiguity is an invariant the domain never checks — DEFERRED, do not touch

- **Where (enforced today):** only implicitly — [reorder_move_resolver.dart](mobile/lib/modules/workout_overview/services/reorder_move_resolver.dart) ("a standalone exercise jumps over a whole superset; a member can never escape its group") and [drop_resolver.dart](mobile/lib/modules/workout_overview/services/drop_resolver.dart) only ever *offer* legal targets.
- **The gap:** `SessionFlowEngine.reorderUnfinished` validates that the input is an exact permutation of unfinished ids ([session_flow_engine.dart:158-168](mobile/lib/modules/domain/services/session_flow_engine.dart#L158-L168)) but accepts permutations that interleave superset members with outsiders — silently splitting a group, since group identity is *defined* by contiguous same-tag runs. The engine's own docs acknowledge the assembler's contiguous-run detection; the invariant just isn't asserted.
- **Suggestion (not adopted):** add a check in `reorderUnfinished` that each superset tag's members remain contiguous, throwing `ValidationError(invariant: 'superset_contiguity')`.
- **Decision (2026-06-11): deferred — leave the engine permissive.** Today the only way to pull one exercise out of a superset is to disband the whole group, which is poor UX; a future interaction may *intentionally* produce a run-splitting reorder. Hard-enforcing contiguity now could block that. Revisit alongside the superset UX redesign.

### 6. The "effective exercise" projection is re-implemented five times, with divergences

Resolving a `SessionExercise` against the snapshot (or its substitute) is duplicated in:

| Copy | Location | Divergence |
| --- | --- | --- |
| Engine (private) | [session_flow_engine.dart:598-692](mobile/lib/modules/domain/services/session_flow_engine.dart#L598-L692) | throws `NotFoundError` on missing planned exercise |
| Drift repo | [drift_session_repository.dart:1245-1288](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L1245-L1288) | `_plannedSetCountForExercise` **returns 0** when not found (engine throws) |
| Overview assembler | [exercise_view_model_assembler.dart:24-66](mobile/lib/modules/workout_overview/services/exercise_view_model_assembler.dart#L24-L66) | falls back to `ExerciseGroupRole.main` |
| Focus assembler | [focus_mode_assembler.dart:272-402](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart#L272-L402) | falls back to `main`; recomputes `isLoggable` instead of using `openTargets` |
| Measurement-type/values match | engine `_validateMeasurementTypeMatch`, repo `_validateActualValues`, focus bloc `_matches` ([focus_mode_bloc.dart:903-910](mobile/lib/modules/focus_mode/bloc/focus_mode_bloc.dart#L903-L910)) | three identical switch statements |

- **Suggestion:** introduce a domain projection — e.g. an `EffectiveExercise` view (or extension methods on `Session`): `effectiveMeasurementTypeOf(sessionExercise)`, `plannedSetCountOf(...)`, `displayNameOf(...)`, `plannedGroupRoleOf(...)`, `plannedExerciseOf(...)` — plus `ActualSetValues.matches(MeasurementType)` on the value object itself. The engine, repo, and both assemblers consume it; the not-found and group-role fallback behavior gets decided once.

### 7. Program-authoring bounds exist only at the UI edge

- **Where:** [program_validation.dart](mobile/lib/modules/program_management/services/program_validation.dart) (program_management module).
- **The gap:** domain models enforce structural invariants (non-negative weight, half-kg resolution, `min < max` ranges, superset cardinality), but the *business bounds* — weight ≤ 1000 kg, reps ≤ 999, duration/rest ≤ 3600 s, set count 1–20, name lengths — live only in the UI service. Anything that writes through `ProgramRepository` directly (text-plan import, future sync, tests) can persist a 5000 kg set. Note also `ProgramAggregate` and friends ([program_aggregate.dart](mobile/lib/modules/domain/models/program_aggregate.dart)) carry **no invariants at all**, unlike their snapshot-side twins.
- **Inconsistency found:** `validateProgramName` allows 120 chars on create but 100 on edit ([program_validation.dart:24-25](mobile/lib/modules/program_management/services/program_validation.dart#L24-L25)) — almost certainly unintended.
- **Suggestion:** move the numeric/text bounds into domain — either onto the aggregate models' `._()` constructors (the established freezed-validation convention) or as a `ProgramRules` domain service the UI validator delegates to. Keep string-parsing (`parseRepTarget`'s en-dash handling, `double.tryParse`) in the UI service; parsing is an input concern, the *bounds* are not. `parseRepTarget` is a reasonable candidate for `RepTarget.parse(...)` in domain since "6–8" is ubiquitous-language notation, not just UI formatting.

### 8. Two competing definitions of "the active session"

- **Where:** [drift_session_repository.dart:155-164](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L155-L164) (`getActiveSession`: in-progress session with latest `startedAt`) vs [session_history_summarizer.dart:40-46](mobile/lib/modules/workout_day_picker/services/session_history_summarizer.dart#L40-L46) (`_beats`: latest `updatedAt`, then `startedAt`, then id).
- **Why it matters:** with two in-progress sessions in the database (possible today — see finding 2), the day-picker tile's "resume" target and the global active session can disagree. This is a ubiquitous-language failure: "active session" means different things in two layers.
- **Suggestion:** define one domain policy (e.g. `ActiveSessionPolicy.select(List<Session>) → Session?`) and have both the repository query ordering and the summarizer use it. Fixing finding 2 makes the tie-break nearly unreachable, which is exactly when a single definition should be locked in.

---

## P2 — Domain policies stranded in feature modules

### 9. Focus-mode rotation and progression policy

- **Where:** [focus_mode_assembler.dart:77-143](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart#L77-L143) (`_pickActivePanelId` — the focus.md §3.3 rule: loggable panels only; fewest completed sets wins; ties broken by rotation after the most recent log; user pin overrides) and [focus_mode_assembler.dart:187-234](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart#L187-L234) (`findNextAnchorAfter` — forward-with-wraparound search for the next group with open targets).
- **Why this is domain:** this is how the app decides *what the lifter does next* — written against `SessionExercise`/`ExecutedSet`/`LogTarget` only, no view models needed for the core decision. The overview bloc independently implements the sibling "active group" concept ([workout_overview_bloc.dart:404-437](mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart#L404-L437)); both should share one vocabulary.
- **Suggestion:** a domain service (e.g. `GroupProgression` / `SupersetRotationPolicy` beside `superset_grouping.dart`) exposing `activeExerciseIn(group, pinnedId)`, `nextGroupAfter(session, anchorId)`, and `activeGroupOf(sessionState)`. The assemblers keep view-model construction; the bloc's `_activeGroupKey`/`_activeGroupLoggableIds` collapse into calls.

### 10. Session-history derivations

- **Where:** [session_history_summarizer.dart](mobile/lib/modules/workout_day_picker/services/session_history_summarizer.dart) (last-completed date, total/this-week counts, best active session) and [session_history_assembler.dart](mobile/lib/modules/export/services/session_history_assembler.dart) (completed-only filter, newest-first ordering with id tie-break, completed-exercise counting, week bucketing).
- **Why this is domain:** pure `List<Session>` computations defining coach-facing numbers ("completed this week" feeds the weekly report). The export module again reaches into `workout_day_picker` for the window type.
- **Suggestion:** a `SessionHistory` domain service (or extensions on `List<Session>`) producing these summaries; both feature modules consume it. Moves with finding 3.

### 11. The link-suggestion policy and its apply use case

- **Where:** [link_suggester.dart](mobile/lib/modules/exercise_library/services/link_suggester.dart) (cluster on `(trimmed lowercase name, measurementType)`; longest name and first video win) and [link_suggestion_bloc.dart:60-95](mobile/lib/modules/exercise_library/bloc/link_suggestion/link_suggestion_bloc.dart#L60-L95) (`_onClusterAccepted`: create a `LibraryExercise`, then loop-update every referenced exercise across all programs — non-transactional, in a bloc).
- **Why this is domain:** "what makes two template exercises the same exercise" is an identity rule for the library context; the accept flow is a cross-aggregate use case (Library + Program) that belongs in a domain/application service, not least so it can someday be wrapped in one transaction. The bloc also hand-rolls a `Program`+`WorkoutDay` → `ProgramAggregate` remapping ([link_suggestion_bloc.dart:122-188](mobile/lib/modules/exercise_library/bloc/link_suggestion/link_suggestion_bloc.dart#L122-L188)) that duplicates structure-mapping the repos already own.
- **Suggestion:** move `LinkSuggester` to `domain/services/` as-is (it is already pure and only consumes domain types), and extract an `ExerciseLinkingService.applyCluster(cluster)` that owns the create-and-link sequence. Consider a repository method that performs the bulk link transactionally.

### 12. Session instantiation (snapshot flattening) is a repository private

- **Where:** [drift_session_repository.dart:74-97](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L74-L97) (`startSession`): flatten groups → per-exercise rows, derive `supersetTag` from `group.kind is SupersetKind ? group.id : null`, assign gap-spaced positions.
- **Why this is domain:** "how a planned day becomes a live session" — including the planned-superset → session-superset translation — is the birth of the aggregate. The gap constant (1024) can stay a persistence detail, but the *order and tag derivation* define meaning.
- **Suggestion:** a domain factory, e.g. `SessionSeed.fromWorkoutDay(day) → List<({plannedExerciseId, supersetTag})>`, which the repo turns into rows. This also gives the dormant Replace redesign and any future "start from mid-week edit" feature one place to look.

---

## P3 — Smaller alignments

### 13. `IncrementRules` is domain policy parked in `core/`

[increment_rules.dart](mobile/lib/core/increment_rules.dart) encodes logging policy from the MVP design doc (±1 kg ≤ 10 kg else ±2.5; half-kg rounding explicitly tied to the domain invariant `weightKg_half_kg_resolution`). `core/` is for cross-cutting infrastructure (theme, clock, canonical JSON); these are training rules. Low urgency since `core` is pure and importable by domain, but `domain/services/` is the truthful home — especially `roundHalfKg`, which exists *because of* a domain invariant.

### 14. Substitute summary formatting duplicates `PlannedSummaryFormatter`

[focus_mode_assembler.dart:373-385](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart#L373-L385) (`_summarizeSubstitute`) re-implements the exact format strings of [planned_summary_formatter.dart](mobile/lib/core/planned_summary_formatter.dart) because the latter only accepts `Exercise`. Add a `summarizeValues(PlannedSetValues, setCount)` overload (or extend domain's `SetValueFormatter`) and delete the copy — these two will silently drift on the next wording change.

### 15. Group-kind derivation duplicated in the editor draft

[program_editor_draft.dart:165-167](mobile/lib/modules/program_management/models/program_editor_draft.dart#L165-L167): `kind() => exercises.length == 1 ? single : superset` is the constructive dual of `ExerciseGroup`'s validation invariant. Harmless today, but the rule "group kind is determined by member count" should be stated once — e.g. `ExerciseGroupKind.forMemberCount(int)` in domain, used by both the draft and the validator.

### 16. Set-row pairing logic in the overview assembler

[exercise_view_model_assembler.dart:106-155](mobile/lib/modules/workout_overview/services/exercise_view_model_assembler.dart#L106-L155) (`_buildSetRows`) decides how executed sets pair positionally with planned sets, including overflow "extra set" rows and the suggested-values rule. The presentation parts (row view models) are rightly UI; the *pairing semantics* (planned-index ↔ executed-index alignment, what counts as an extra set) is shared meaning the post-session review reuses and exports may need. Worth extracting as a domain pairing function when exports next touch per-set data — not urgent before then.

---

## Ubiquitous-language notes (no code change required, worth deciding)

- **"Completed" is overloaded** — auto-completed (quota met) vs marked done early (fewer sets, work preserved). The states are identical in data; exports and coach reports may eventually care. If they do, that distinction must be modeled, not inferred.
- **"Superset" names two models** — planned (`ExerciseGroup(kind: superset)`) and live (contiguous tag run). The translation happens exactly once (session start). Keep, but document in product-context.md; the glossary entries [Superset](.plans/domain/Superset.md) and [ExerciseGroup](.plans/domain/ExerciseGroup.md) record the distinction.
- **"Open target" vs "loggable"** — `LogTarget`/`openTargets` in domain, `isLoggable` in every view model. Consistent enough, but new code should prefer deriving `isLoggable` from `openTargets` (the focus assembler currently recomputes it — see finding 6).
- **Replace/`ReplacedState` is deliberately dormant** (UI removed 2026-06-11 pending redesign). Several findings above (6, 12) reduce the number of places the Replace redesign will have to touch — a side benefit, not a goal.

## Agreed implementation scope (input for /plan)

The decision log above is binding. The work below is the full batch, in dependency order. Everything lands in pure Dart inside the existing test scope (`test/domain`, `test/modules`, `test/integration`) — no new test infrastructure.

### Step group A — Effective-exercise projection (finding 6, unblocks B)
1. New `domain/services/effective_exercises.dart`: `EffectiveExercises.of(Session)` builds the snapshot index once; exposes per-session-exercise `effectiveMeasurementType`, `plannedSetCount`, `displayName`, `plannedGroupRole`, `plannedExercise`, handling `ReplacedState` substitutes. Missing planned exercise → `NotFoundError` (always).
2. `ActualSetValues.matches(MeasurementType)` on the value object.
3. Migrate consumers and delete the five private copies: engine (`_lookupPlannedExercise`, `_lookupPlannedSetCount`, `_lookupPlannedValuesAtPosition`, `_effectiveMeasurementType`, `_validateMeasurementTypeMatch`), Drift session repo (`_measurementTypeForExercise`, `_plannedSetCountForExercise`, `_validateActualValues`), `ExerciseViewModelAssembler`, `FocusModeAssembler` (`_lookupPlanned`, `_resolveGroupRole`, `_displayName`), `FocusModeBloc._matches`.
4. **Behavior change to pin with a test:** the repo path that returned planned-set-count 0 for a missing snapshot exercise now throws (no more silent auto-complete on corrupt data).

### Step group B — Transitions and ordering out of the repo (findings 1, 4, 12)
5. `domain/services/exercise_state_transitions.dart`: `afterSetLogged(state, executedCount, plannedCount)` (auto-complete only from `unfinished`) and `afterSetDeleted(...)` (revert `completed` → `unfinished` below quota). Drift repo's `completeSet`/`deleteExecutedSet` delegate, inside their existing transactions.
6. `domain/` superset ordering (beside `superset_grouping.dart`): `blockedOrderForCreate(allIds, chosenIds)` (contiguous block anchored at the earliest chosen member) and `orderForAppend(unfinishedIds, memberIds, draggedId)` (insert after last member). Repo maps the returned order onto position slots; the two-phase UNIQUE-dodging writes stay in the repo.
7. `domain/` session seeding: `SessionSeed.fromWorkoutDay(day)` → ordered `(plannedExerciseIdInSnapshot, supersetTag)` list (tag = group id when kind is superset). Repo's `startSession` consumes it; the position-gap constant stays a repo detail.
8. Existing Drift integration tests pin all of this — extend with pure-Dart unit tests for the new domain functions.

### Step group C — Active-session policy (finding 8)
9. Domain `ActiveSessionPolicy`: select among in-progress sessions by `updatedAt` desc, then `startedAt` desc, then id desc. `SessionHistorySummarizer._beats` delegates to it; Drift repo's `getActiveSession`/`watchActiveSession` ordering changes from `startedAt` to `updatedAt` (keep the secondary ordering deterministic).

### Step group D — TrainingWeek cluster (findings 3, 10)
10. Move `CurrentWeekWindow` → `domain/models/training_week.dart`, renamed `TrainingWeek` (Monday start stays hardcoded). Freezed codegen: run `dart run build_runner build --force-jit`.
11. Move `SessionEditability.canEditValues` → domain policy beside it.
12. Move the history derivations (`SessionHistorySummarizer`, the computational core of `SessionHistoryAssembler`: completed-only filter, newest-first + id tie-break ordering, completed-exercise counts, week bucketing) → domain `SessionHistory` service. Feature modules keep only view-model wrapping. This removes every `export/` → `workout_day_picker/` import.

### Step group E — Program rules (finding 7)
13. Domain `ProgramRules`: bound constants (weight ≤ 1000 in half-kg steps, reps ≤ 999, duration/rest ≤ 3600, set count 1–20, exercise name ≤ 80, day name ≤ 100, **program name ≤ 100 — also on create**, video-url and notes rules) + validate methods producing `ValidationError`s.
14. Enforce at the write path: `AggregateSaver.save` (or `ProgramRepository.saveProgramAggregate`) validates before persisting. No constructor validation on the aggregates — legacy rows must keep loading.
15. `ProgramValidation` (UI) delegates bounds to `ProgramRules`, keeping input parsing and error-code mapping. `parseRepTarget` moves to domain as `RepTarget.parse` (en-dash/hyphen range notation); UI calls it.

### Step group F — Small moves (findings 11-partial, 14, 15)
16. `LinkSuggester` → `domain/services/` unchanged (it already uses only domain types). Update imports/barrel.
17. Planned-summary formatting: add a `(PlannedSetValues, setCount)` overload (in `core/planned_summary_formatter.dart` or domain `SetValueFormatter` — implementer's choice); delete `FocusModeAssembler._summarizeSubstitute`.
18. `ExerciseGroupKind.forMemberCount(int)` in domain; `ExerciseGroupDraft.kind()` and `ExerciseGroup`'s validation both express the rule through it.

### Explicitly out of scope — do not implement
- **Single-active-session enforcement in the engine** (finding 2 — UI-only by design, coach+trainee future).
- **Superset-contiguity validation in `reorderUnfinished`** (finding 5 — deferred pending superset UX redesign).
- **Focus rotation/progression policy move** (finding 9 — opportunistic).
- **`ExerciseLinkingService` / transactional bulk link** (finding 11 remainder — opportunistic).
- **`IncrementRules` relocation** (finding 13), **set-row pairing extraction** (finding 16).
- Anything touching the dormant Replace/`ReplacedState` surface beyond mechanical adoption of the new projection.

### Plan constraints
- Run `tool/ci.sh` (imports → codegen → format → analyze → test) at every step boundary; codegen requires `--force-jit`.
- New tests are pure Dart under `test/domain` / `test/modules`; Drift behavior changes (repo delegation, ORDER BY) get coverage in `test/integration` with `makeInMemoryDatabase()`.
- No `bloc_test`, no widget tests.
- Generated files are committed; never hand-edit.

### Post-implementation cleanup
- **Delete `.plans/` once this plan is fully implemented.** The glossary under `.plans/domain/` is a derived snapshot of the pre-refactor code — several entries (TrainingWeek, LinkSuggestion, SessionFlowEngine, Session) become factually wrong the moment the step groups land, and it has no maintenance mechanism, so keeping it means keeping confidently stale documentation. It can be regenerated on demand from the code if ever needed (e.g. to feed `domain-review`).
- Before deleting, fold any decision-bearing nuggets worth preserving into product-context.md (e.g. "superset" deliberately names two models — planned group vs live tag run; "completed" covers both quota-met auto-completion and explicit mark-done). The decision rationale itself is already recorded in this file's decision log, which remains the historical record.
