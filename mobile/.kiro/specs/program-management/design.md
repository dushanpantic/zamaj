# Design Document

## Introduction

This design turns the **program-management** requirements into an implementable
plan for the first UI layer of Zamaj. It binds every requirement (R1–R15) to
concrete files, types, BLoCs, and data flows, and explicitly anchors every
domain call to signatures that already exist in `lib/modules/domain/` or to a
single, minimal extension this spec adds (`Exercise.plannedRestSeconds`).

The design respects four non-negotiable constraints:

- **Offline-first isolation** — `lib/modules/program_management/` will not
  import any networking package or `dart:io` HTTP/socket classes. The only
  outbound boundary is `ExternalLinkLauncher` (R7, R13).
- **Repository contracts only** — the UI layer depends on `ProgramRepository`
  and `SessionRepository` (read-only) via constructor injection; no Drift
  types leak (R12).
- **Historical immutability** — editing a program goes exclusively through
  `ProgramRepository`; session snapshots are byte-stable (R11).
- **Extensibility** — every `MeasurementType` and `ExerciseGroupKind` decision
  routes through the existing sealed freezed unions so adding a new variant
  does not touch persisted data (R4 AC5, R5 AC9).

---

## 1. High-Level Architecture

### 1.1 Layering

```
┌──────────────────────────────────────────────────────────────────┐
│ lib/modules/program_management/               (THIS SPEC)         │
│                                                                   │
│  screens/ ──► widgets/ ──► bloc/ ──► services/ ──► models/        │
│                           │                                       │
│                           └──► domain.dart barrel                 │
│                                (Program, WorkoutDay,              │
│                                 ExerciseGroup, Exercise,          │
│                                 WorkoutSet, MeasurementType,      │
│                                 ExerciseGroupKind,                │
│                                 ExerciseMetadata,                 │
│                                 ProgramRepository,                │
│                                 SessionRepository,                │
│                                 DomainError)                      │
├──────────────────────────────────────────────────────────────────┤
│ lib/modules/domain/               (UNCHANGED EXCEPT Exercise)     │
│ lib/modules/persistence/          (REPOSITORY IMPL + MIGRATION)   │
│ lib/core/                          (CanonicalJson, AppClock,      │
│                                     AppError, SchemaVersions)     │
└──────────────────────────────────────────────────────────────────┘
```

The module has no knowledge of Drift, `dart:io`, or networking packages.
`ProgramRepository` and `SessionRepository` are abstract contracts that
already live under `lib/modules/domain/repositories/`; the Drift-backed
implementations live under `lib/modules/persistence/repositories/` and are
wired in at app-composition time (not inside the module).

### 1.2 Module Folder Structure

```
lib/modules/program_management/
├── program_management.dart                  # Public barrel export
├── bloc/
│   ├── program_list/
│   │   ├── program_list_bloc.dart
│   │   ├── program_list_event.dart
│   │   ├── program_list_state.dart
│   │   └── bloc.dart                        # sub-barrel
│   ├── program_editor/
│   │   ├── program_editor_bloc.dart
│   │   ├── program_editor_event.dart
│   │   ├── program_editor_state.dart
│   │   └── bloc.dart
│   ├── workout_day_editor/
│   │   ├── workout_day_editor_bloc.dart
│   │   ├── workout_day_editor_event.dart
│   │   ├── workout_day_editor_state.dart
│   │   └── bloc.dart
│   ├── exercise_editor/
│   │   ├── exercise_editor_bloc.dart
│   │   ├── exercise_editor_event.dart
│   │   ├── exercise_editor_state.dart
│   │   └── bloc.dart
│   ├── plan_import/
│   │   ├── plan_import_bloc.dart
│   │   ├── plan_import_event.dart
│   │   ├── plan_import_state.dart
│   │   └── bloc.dart
│   └── plan_preview/
│       ├── plan_preview_bloc.dart
│       ├── plan_preview_event.dart
│       ├── plan_preview_state.dart
│       └── bloc.dart
├── screens/
│   ├── program_list_screen.dart
│   ├── program_editor_screen.dart
│   ├── workout_day_editor_screen.dart
│   ├── exercise_editor_screen.dart
│   ├── plan_import_screen.dart
│   └── plan_preview_screen.dart
├── widgets/
│   ├── program_list_tile.dart
│   ├── workout_day_list_tile.dart
│   ├── exercise_group_card.dart
│   ├── exercise_tile.dart
│   ├── planned_set_row.dart
│   ├── measurement_type_selector.dart
│   ├── plan_text_input.dart
│   ├── plan_parse_error_banner.dart
│   ├── domain_error_banner.dart
│   └── confirmation_dialog.dart
├── services/
│   ├── text_plan/
│   │   ├── plan_draft.dart                  # freezed
│   │   ├── plan_parse_error.dart            # freezed
│   │   ├── plan_parse_warning.dart          # freezed
│   │   ├── parse_result.dart                # freezed sealed
│   │   ├── text_plan_parser.dart
│   │   └── plan_pretty_printer.dart
│   ├── external_link_launcher.dart          # abstract + concrete
│   ├── program_validation.dart
│   ├── domain_error_presenter.dart
│   ├── plan_draft_to_aggregate.dart         # PlanDraft → ProgramAggregate
│   └── aggregate_saver.dart                 # transactional save
├── models/
│   ├── program_editor_draft.dart            # ProgramDraft, WorkoutDayDraft,…
│   └── program_aggregate.dart               # complete aggregate in memory
└── navigation/
    ├── program_management_routes.dart       # route name constants
    └── program_management_router.dart       # onGenerateRoute
```

### 1.3 Dependency Injection

`flutter_bloc`, `bloc_test`, and `provider` are not yet in `pubspec.yaml`.
They will be added under **Dependencies (to add)** in Section 14.

Composition (outside the module, inside `lib/app.dart` and `lib/bootstrap.dart`):

```dart
// lib/bootstrap.dart (new)
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  final db = AppDatabase(/* drift_flutter executor */);
  final clock = const AppClock();
  final programRepo  = DriftProgramRepository(db, clock);   // from persistence
  final sessionRepo  = DriftSessionRepository(db, clock);
  runApp(MainApp(programRepo: programRepo, sessionRepo: sessionRepo));
}
```

```dart
// lib/app.dart (new)
class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.programRepo, required this.sessionRepo});
  final ProgramRepository programRepo;
  final SessionRepository sessionRepo;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProgramRepository>.value(value: programRepo),
        RepositoryProvider<SessionRepository>.value(value: sessionRepo),
        RepositoryProvider<ExternalLinkLauncher>(
          create: (_) => const UrlLauncherExternalLinkLauncher(),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: ProgramManagementRouter.onGenerateRoute,
        initialRoute: ProgramManagementRoutes.programList,
      ),
    );
  }
}
```

BLoCs receive their dependencies via constructor injection (R12 AC3).
Screens obtain them from `context.read<ProgramRepository>()` inside
`BlocProvider` callbacks; screens do not own the repository references.

---

## 2. Screens and Navigation

### 2.1 Navigation Approach

We use **plain Navigator 1.0 with `onGenerateRoute`** — no `go_router`
dependency. The feature graph is shallow (6 routes) and modal-heavy; a
router abstraction would be pure overhead. Route names live in
`ProgramManagementRoutes`:

```dart
abstract final class ProgramManagementRoutes {
  static const programList   = '/programs';
  static const programEditor = '/programs/editor';   // args: ProgramEditorArgs
  static const workoutDay    = '/programs/workout-day'; // args: WorkoutDayArgs
  static const exercise      = '/programs/exercise';    // args: ExerciseArgs
  static const planImport    = '/programs/import';
  static const planPreview   = '/programs/import/preview';
}
```

### 2.2 Screen Catalog

| Screen | Purpose | Key widgets | States surfaced |
|---|---|---|---|
| `ProgramListScreen` | List, delete, navigate to editor, launch import (R1) | `ListView.builder`, `ProgramListTile`, empty-state, `FloatingActionButton` | loading, loaded(List<Program>), empty, failure(retry), deleting |
| `ProgramEditorScreen` | Create or edit a Program; add/delete/reorder workout days (R2, R3) | `AppBar` with name field, `ReorderableListView` of `WorkoutDayListTile`, `ConfirmationDialog` | editingDraft(ProgramDraft), saving, failure, notFound |
| `WorkoutDayEditorScreen` | Manage exercise groups, Single/Superset conversion, exercise ordering (R4) | `ReorderableListView` of `ExerciseGroupCard`, drag-to-superset gesture handler, inline validation banner | editingDraft(WorkoutDayDraft), saving, validationError, failure, notFound |
| `ExerciseEditorScreen` | Author name, Measurement_Type, metadata, planned sets, rest (R5, R6, R7) | `TextField` name, `MeasurementTypeSelector`, notes/video-URL fields, `ReorderableListView` of `PlannedSetRow`, `PlannedRestField` | editingDraft(ExerciseDraft), measurementChangeConfirming, saving, validationError, failure |
| `PlanImportScreen` (paste surface) | Accept pasted Plan_Text, invoke parser, navigate to preview on success (R8) | `PlanTextInput` (multi-line, 100k code-unit cap), `PlanParseErrorBanner`, "Parse" button | idle, parsing, failure(PlanParseError), success(PlanDraft) |
| `PlanPreviewScreen` | Render parsed Plan_Draft in editable structured form, save atomically (R9) | Same widgets as `ProgramEditorScreen` + nested workout-day/exercise views, warnings-inline, "Save"/"Discard" | previewing(ProgramDraft, warnings), saving, validationError, saveFailure |

Every screen exposes these three universal surfaces, implemented in
`widgets/state/`:

- `LoadingView(label)` — centred spinner + label
- `EmptyView(action)` — illustration/text + CTA
- `ErrorView(message, onRetry)` — error message + retry button

### 2.3 Navigation Flow

```
ProgramListScreen
  ├─► ProgramEditorScreen(create)     [FAB: + new]
  ├─► ProgramEditorScreen(edit id)    [tap tile]
  └─► PlanImportScreen                 [FAB: paste]
       └─► PlanPreviewScreen           [on parse success]

ProgramEditorScreen
  └─► WorkoutDayEditorScreen(workoutDayId)

WorkoutDayEditorScreen
  └─► ExerciseEditorScreen(exerciseId)
```

Navigating back from an editor pops to the parent; list refreshes happen via
a BlocListener on `ProgramListScreen` that re-requests `ProgramListLoaded`
on route resume (`RouteAware` mixin or a simpler
`Navigator.push(...).then((_) => bloc.add(ProgramListRequested()))`).

---

## 3. BLoC Design

All events and states extend `Equatable` and live in sealed class families,
per `init.md` conventions.

### 3.1 `ProgramListBloc`

**Events**

```dart
sealed class ProgramListEvent extends Equatable { ... }
final class ProgramListRequested    extends ProgramListEvent {}
final class ProgramListDeleteRequested extends ProgramListEvent { final String programId; }
final class ProgramListDeleteConfirmed extends ProgramListEvent { final String programId; }
final class ProgramListDeleteCancelled extends ProgramListEvent { final String programId; }
final class ProgramListRetryRequested  extends ProgramListEvent {}
```

**States**

```dart
sealed class ProgramListState extends Equatable { ... }
final class ProgramListInitial  extends ProgramListState {}
final class ProgramListLoading  extends ProgramListState {}
final class ProgramListLoaded   extends ProgramListState {
  final List<Program> programs;                     // sorted per R1 AC2
  final String? deletionCandidateId;                 // confirmation in flight
  final DomainError? lastDeleteError;                // R1 AC10
}
final class ProgramListFailure  extends ProgramListState { final DomainError error; } // R1 AC9
```

**Transitions**

| Trigger | From | To |
|---|---|---|
| `ProgramListRequested` | * | `ProgramListLoading` then `Loaded` or `Failure` |
| `ProgramListDeleteRequested` | `Loaded` | `Loaded(deletionCandidateId=id)` |
| `ProgramListDeleteConfirmed` | `Loaded(deletionCandidateId)` | `Loading` then `Loaded` (on success, R1 AC7) or `Loaded(lastDeleteError)` (R1 AC10) |
| `ProgramListDeleteCancelled` | `Loaded(deletionCandidateId)` | `Loaded(deletionCandidateId=null)` |
| `ProgramListRetryRequested` | `Failure` | `Loading` then `Loaded`/`Failure` |

**Sort key (R1 AC2)** — deterministic tie-break:

```dart
programs.sort((a, b) {
  final cmp = b.updatedAt.compareTo(a.updatedAt); // desc
  if (cmp != 0) return cmp;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
});
```

### 3.2 `ProgramEditorBloc`

Owns a `ProgramDraft` (see Section 4) for both create and edit modes.

**Events**

```dart
final class ProgramEditorOpened        extends ProgramEditorEvent { final String? programId; } // null = create
final class ProgramEditorNameChanged   extends ProgramEditorEvent { final String name; }
final class ProgramEditorWorkoutDayAdded extends ProgramEditorEvent { final String name; }
final class ProgramEditorWorkoutDayRenamed extends ProgramEditorEvent { final String draftId; final String name; }
final class ProgramEditorWorkoutDayDeleteRequested extends ProgramEditorEvent { final String draftId; }
final class ProgramEditorWorkoutDayDeleteConfirmed extends ProgramEditorEvent { final String draftId; }
final class ProgramEditorWorkoutDayDeleteCancelled extends ProgramEditorEvent {}
final class ProgramEditorWorkoutDaysReordered extends ProgramEditorEvent { final List<String> orderedDraftIds; }
final class ProgramEditorSavePressed   extends ProgramEditorEvent {}
```

**States**

```dart
final class ProgramEditorNotFound  extends ProgramEditorState { final String programId; } // R3 AC2
final class ProgramEditorLoading   extends ProgramEditorState {}
final class ProgramEditorEditing   extends ProgramEditorState {
  final ProgramDraft draft;
  final bool isCreateMode;
  final String? deletionCandidateDraftId;
  final ProgramDraftValidation validation;   // recomputed on every draft mutation
  final DomainError? lastSaveError;
}
final class ProgramEditorSaving    extends ProgramEditorState { final ProgramDraft draft; }
final class ProgramEditorSaved     extends ProgramEditorState { final String programId; } // triggers navigation pop / replace
```

**Save flow (create mode, R2 AC3–AC6)**

```
ProgramEditorSavePressed
  ├─ validation.isNameValid → true
  ├─ emit ProgramEditorSaving(draft)
  ├─ AggregateSaver.saveNewProgram(draft)           // Section 8
  │     ├─ programRepo.createProgram(name)
  │     ├─ for each WorkoutDayDraft in draft:
  │     │     programRepo.createWorkoutDay(programId, name)
  │     └─ returns Program
  ├─ on success: emit ProgramEditorSaved(programId)
  └─ on DomainError: emit ProgramEditorEditing(draft, lastSaveError: e)
```

**Save flow (edit mode, R3 AC3–AC9)** — diff-based:

Compare draft against the loaded baseline; issue the minimum set of
`updateProgram`, `createWorkoutDay`, `deleteWorkoutDay`, `reorderWorkoutDays`
calls. The diff algorithm is deterministic and lives in
`services/aggregate_saver.dart`. On any `DomainError`, emit the editing state
with the error; the user retries (R3 AC5 for name too long).

### 3.3 `WorkoutDayEditorBloc`

Operates on a `WorkoutDayDraft`. Explicit save action (not autosave) to keep
R4 AC3/AC4 predictable.

**Events** (representative)

```dart
final class WorkoutDayEditorOpened       extends WorkoutDayEditorEvent { final String workoutDayId; }
final class WorkoutDayNameChanged        extends WorkoutDayEditorEvent { final String name; }
final class ExerciseGroupAdded           extends WorkoutDayEditorEvent {}   // empty Single placeholder (not saved until Exercise added)
final class ExerciseGroupDeleted         extends WorkoutDayEditorEvent { final String groupDraftId; }
final class ExerciseGroupsReordered      extends WorkoutDayEditorEvent { final List<String> orderedGroupDraftIds; }
final class ExerciseAddedToGroup         extends WorkoutDayEditorEvent { final String groupDraftId; final String exerciseName; final MeasurementType measurementType; }
final class ExerciseRemovedFromGroup     extends WorkoutDayEditorEvent { final String groupDraftId; final String exerciseDraftId; }
final class ExerciseReorderedWithinGroup extends WorkoutDayEditorEvent { final String groupDraftId; final List<String> orderedExerciseDraftIds; }
final class GroupSavePressed             extends WorkoutDayEditorEvent { final String groupDraftId; } // persists that group
final class WorkoutDayExercisePressed    extends WorkoutDayEditorEvent { final String exerciseDraftId; } // navigates to ExerciseEditor
```

**States** include `WorkoutDayEditorEditing(draft, validation, lastSaveError)`,
`WorkoutDayEditorSaving`, `WorkoutDayEditorNotFound` (R4 AC7), and transient
`WorkoutDayEditorGroupValidationError(groupDraftId, invariant)` for the
cardinality-violation path (R4 AC4).

**Group-save algorithm (R4 AC3)**

```
GroupSavePressed(groupDraftId)
  ├─ locate group in draft
  ├─ if group.exercises.length == 1 → kind = single
  │  else if group.exercises.length >= 2 → kind = superset
  │  else → emit GroupValidationError(invariant='empty_group')
  ├─ call ProgramRepository.updateExerciseGroup or
  │       ProgramRepository.createExerciseGroup depending on id presence
  ├─ on ValidationError with invariant in {single_requires_exactly_one_exercise,
  │    superset_requires_at_least_two_exercises}:
  │      emit GroupValidationError (unsaved edits retained)  — R4 AC4
  └─ on any other DomainError: emit Editing(lastSaveError=e) — R4 AC8
```

### 3.4 `ExerciseEditorBloc`

**Events**

```dart
final class ExerciseEditorOpened              extends ExerciseEditorEvent { final String exerciseId; }
final class ExerciseNameChanged               extends ExerciseEditorEvent { final String name; }
final class ExerciseMeasurementTypeRequested  extends ExerciseEditorEvent { final MeasurementType next; }
final class ExerciseMeasurementTypeConfirmed  extends ExerciseEditorEvent {}
final class ExerciseMeasurementTypeCancelled  extends ExerciseEditorEvent {}
final class ExerciseNotesChanged              extends ExerciseEditorEvent { final String? notes; }
final class ExerciseVideoUrlChanged           extends ExerciseEditorEvent { final String? videoUrl; }
final class ExerciseVideoUrlActivated         extends ExerciseEditorEvent {}
final class ExercisePlannedRestChanged        extends ExerciseEditorEvent { final String rawInput; }
final class PlannedSetAdded                   extends ExerciseEditorEvent {}    // up to 20 per R5 AC8
final class PlannedSetDeleted                 extends ExerciseEditorEvent { final String setDraftId; } // down to 1
final class PlannedSetReordered               extends ExerciseEditorEvent { final List<String> orderedSetDraftIds; }
final class PlannedSetWeightChanged           extends ExerciseEditorEvent { final String setDraftId; final String rawInput; }
final class PlannedSetRepsChanged             extends ExerciseEditorEvent { final String setDraftId; final String rawInput; }
final class PlannedSetDurationChanged         extends ExerciseEditorEvent { final String setDraftId; final String rawInput; }
final class ExerciseSavePressed               extends ExerciseEditorEvent {}
```

**States** include `ExerciseEditorEditing(draft, validation, pendingMeasurementChange?, lastSaveError?)`,
`ExerciseEditorSaving`, `ExerciseEditorSaved`, `ExerciseEditorFailure`,
and `ExerciseEditorVideoLinkError`.

### 3.5 `PlanImportBloc`

**Events**

```dart
final class PlanImportTextChanged  extends PlanImportEvent { final String text; }
final class PlanImportParseRequested extends PlanImportEvent {}
```

**States**

```dart
final class PlanImportIdle     extends PlanImportState { final String text; }
final class PlanImportParsing  extends PlanImportState { final String text; }
final class PlanImportFailure  extends PlanImportState { final String text; final PlanParseError error; }
final class PlanImportSuccess  extends PlanImportState { final String text; final PlanDraft draft; final List<PlanParseWarning> warnings; }
```

The BLoC calls `TextPlanParser.parse(text)` via a service gateway (so we can
substitute a synchronous fake in tests). The parser is pure Dart; the BLoC
simply awaits and maps.

### 3.6 `PlanPreviewBloc`

Owns a `ProgramDraft` produced from `PlanDraft` via
`PlanDraftToAggregate.convert(draft)`. It emits the same kinds of states as
`ProgramEditorBloc` and reuses the `AggregateSaver`. The key additional
event is `PlanPreviewSavePressed`, which executes an **atomic save**
(Section 8).

### 3.7 Requirement → BLoC Matrix

| Requirement | Primary BLoC |
|---|---|
| R1 | `ProgramListBloc` |
| R2 | `ProgramEditorBloc` (create mode) |
| R3 | `ProgramEditorBloc` (edit mode) |
| R4 | `WorkoutDayEditorBloc` |
| R5 | `ExerciseEditorBloc` |
| R6 | `ExerciseEditorBloc` + domain extension (Section 7) |
| R7 | `ExerciseEditorBloc` + `ExternalLinkLauncher` |
| R8 | `PlanImportBloc` + `TextPlanParser` |
| R9 | `PlanPreviewBloc` + `AggregateSaver` |
| R10 | `TextPlanParser` + `PlanPrettyPrinter` + PBT suite |
| R11 | `AggregateSaver` (never touches `SessionRepository`) |
| R12 | Module import allowlist + constructor-injected BLoCs |
| R13 | Allowlist script extension |
| R14 | Module folder layout + lints |
| R15 | `ProgramValidation` + `DomainErrorPresenter` |

---

## 4. Editor Draft Model

The draft types live in `lib/modules/program_management/models/program_editor_draft.dart`.

```dart
@freezed
abstract class ProgramDraft with _$ProgramDraft {
  const factory ProgramDraft({
    required String? programId,                  // null in create mode
    required String name,
    required List<WorkoutDayDraft> workoutDays,
    required int? schemaVersion,                 // null in create mode
  }) = _ProgramDraft;
  factory ProgramDraft.fromJson(...) => ...;
}

@freezed
abstract class WorkoutDayDraft with _$WorkoutDayDraft {
  const factory WorkoutDayDraft({
    required String draftId,                     // UUID stable for UI keys
    required String? persistedId,                // null if not yet persisted
    required String name,
    required List<ExerciseGroupDraft> groups,
  }) = _WorkoutDayDraft;
}

@freezed
abstract class ExerciseGroupDraft with _$ExerciseGroupDraft {
  const factory ExerciseGroupDraft({
    required String draftId,
    required String? persistedId,
    required List<ExerciseDraft> exercises,       // kind is derived from length
  }) = _ExerciseGroupDraft;
}
// kind is derived: exercises.length == 1 → single, else superset.
// The derivation lives in a pure function ExerciseGroupDraft.kind().

@freezed
abstract class ExerciseDraft with _$ExerciseDraft {
  const factory ExerciseDraft({
    required String draftId,
    required String? persistedId,
    required String name,
    required MeasurementType measurementType,
    required ExerciseMetadata metadata,
    required int? plannedRestSeconds,
    required List<PlannedSetDraft> sets,
  }) = _ExerciseDraft;
}

@freezed
abstract class PlannedSetDraft with _$PlannedSetDraft {
  const factory PlannedSetDraft({
    required String draftId,
    required String? persistedId,
    required PlannedSetDraftValues values,
  }) = _PlannedSetDraft;
}

@Freezed(unionKey: 'type')
sealed class PlannedSetDraftValues with _$PlannedSetDraftValues {
  const factory PlannedSetDraftValues.repBased({
    required String weightInput,    // raw text; validated against 0..1000 @0.5
    required String repsInput,
  }) = PlannedSetDraftRepBased;
  const factory PlannedSetDraftValues.timeBased({
    required String durationInput,  // raw text; validated against 0..3600
  }) = PlannedSetDraftTimeBased;
}
```

**Why raw `String` inputs?** R15 requires that invalid user input is
retained in the field without modification. Drafts therefore hold the
unparsed text; `ProgramValidation` produces the typed `PlannedSetValues`
only when every input parses.

**Draft → domain conversion** (`PlanDraftToAggregate.convert` and
`ProgramDraft.toAggregate`) generates fresh UUIDv4s for any draft without a
`persistedId`, maps `PlannedSetDraftValues` → `PlannedSetValues`, and
assigns `position` values by list index.

---

## 5. Text-Plan Parser and Pretty-Printer

### 5.1 Public API

```dart
// lib/modules/program_management/services/text_plan/text_plan_parser.dart
abstract final class TextPlanParser {
  static ParseResult parse(String input);
}

// lib/modules/program_management/services/text_plan/parse_result.dart
@freezed
sealed class ParseResult with _$ParseResult {
  const factory ParseResult.success({
    required PlanDraft draft,
    required List<PlanParseWarning> warnings,
  }) = PlanParseSuccess;
  const factory ParseResult.failure(PlanParseError error) = PlanParseFailure;
}
```

Pure Dart. No Flutter imports. No `dart:io`. Deterministic (R10 AC2).

### 5.2 Token Grammar

```
LINE         = WS* CONTENT? WS* LINE_TERM?
LINE_TERM    = '\n' | '\r\n'
WS           = ' ' | '\t'                                 // ASCII 0x20, 0x09
MULT_SIGN    = 'x' | 'X' | '×'                            // U+00D7
KG_SUFFIX    = 'kg' | 'KG' | 'Kg' | 'kG'                   // case-folded
SEC_SUFFIX   = 's' | 'S'
MIN_SUFFIX   = 'm' | 'M'
SUPERSET_KW  = 'ss' | 'superset' | 'super-set'             // case-folded
DAY_KW       = 'day'                                       // optional prefix in header

INTEGER      = [0-9]+
DECIMAL      = INTEGER ('.' INTEGER)?

setsByReps   = INTEGER MULT_SIGN INTEGER                   // e.g. 4x8, 4X8, 4×8
weightToken  = DECIMAL KG_SUFFIX                           // e.g. 100kg, 97.5kg
restToken    = INTEGER (SEC_SUFFIX | MIN_SUFFIX)           // e.g. 90s, 2m (1..3600)
durationToken= INTEGER SEC_SUFFIX                          // e.g. 30s
```

### 5.3 Line Classifier (R8 AC4)

Each non-blank line is classified by its first non-whitespace token using
the following ordered rules; the first matching rule wins:

1. **workout-day header** — token matches DAY_KW followed by an identifier
   or ordinal (e.g. `Day 1`, `DAY A`, `day upper`). The whole line after
   "day" becomes the header name.
2. **superset marker** — first token matches SUPERSET_KW. The rest of the
   line up to `:` (if any) is discarded. The next exercise lines belong to
   the current superset until the group closes.
3. **planned-set** — first token matches `setsByReps`. Subsequent tokens on
   the line may be `weightToken`, `durationToken`, or `restToken`.
4. **exercise name** — none of the above, and the current scope has a
   workout day.
5. **blank separator** — entire line matches `WS* LINE_TERM`.

The classifier runs without lookahead except to resolve "first non-blank
line is the program name" when the paste surface did not pre-fill one
(R8 AC3 note).

### 5.4 Classification Algorithm (pseudo-code)

```
parse(input):
  if input.length == 0 || trimmed(input).length == 0:
    return failure(PlanParseError(empty_input, line=1, column=1))
  lines = input.split(/\r\n|\n/)
  scope = { programName: null, currentDay: null, currentGroup: null, warnings: [], days: [] }
  for (i, rawLine) in enumerate(lines):
    line = rawLine.trim()
    if line is blank: continue
    if scope.programName == null and !isDayHeader(line) and !isSetsByReps(line) and !isSupersetMarker(line):
      scope.programName = line; continue
    cls = classify(line)
    switch cls:
      case DayHeader(name):       openDay(scope, name)
      case SupersetMarker:        openSuperset(scope)
      case SetsByReps(...):       attachPlannedSet(scope, cls, line, i+1)
      case ExerciseName(name):    openExercise(scope, name)
      case BlankSeparator:        closeGroupIfOpen(scope)
      case Unknown:               return failure(PlanParseError(unknown_line, line=i+1, column=firstNonWs+1))
  if scope.programName == null or scope.days.empty: return failure(...)
  return success(PlanDraft.fromScope(scope), scope.warnings)
```

### 5.5 Rest Token Handling (R8 AC6, R8 AC7)

On a planned-set line, any trailing token that matches
`restToken` with integer in `[1, 3600]` and unit in `{s, S, m, M}` becomes
the owning exercise's `plannedRestSeconds` (multiplied by 60 for `m`).
If multiple rest tokens appear on a single planned-set line, the last one
wins and the earlier ones emit `PlanParseWarning(invalid_rest_token, ...)`.
Out-of-range or wrong-unit rest-like tokens become warnings per R8 AC7.

### 5.6 Error and Warning Codes

```dart
@freezed
abstract class PlanParseError with _$PlanParseError {
  const factory PlanParseError({
    required int line,         // 1-based
    required int column,       // 1-based
    required PlanParseErrorCode code,
    required String message,
  }) = _PlanParseError;
}

enum PlanParseErrorCode {
  empty_input,
  unknown_line,
  missing_program_name,
  missing_workout_day,
  orphan_set_line,
  orphan_superset_marker,
  input_too_large,
}

@freezed
abstract class PlanParseWarning with _$PlanParseWarning {
  const factory PlanParseWarning({
    required int line,
    required int column,
    required PlanParseWarningCode code,
    required String offendingToken,
    required String exerciseDraftId,   // owner per R8 AC9
  }) = _PlanParseWarning;
}

enum PlanParseWarningCode {
  invalid_rest_token,
  unrecognized_trailing_token,
}
```

### 5.7 Pretty-Printer

`PlanPrettyPrinter.print(PlanDraft draft) → String` emits a canonical form:

- program name on line 1, blank line;
- each workout day: `Day <name>` header, blank line;
- each group: if superset, `Superset:` marker, then each exercise;
- each exercise: name on a line, followed by one planned-set line per set;
- planned-set line format:
  - rep-based: `<reps>x<count> <weight>kg` (no space around `x`), then
    `<rest>s` if present;
  - time-based: `<count>x<duration>s`, then `<rest>s` if present;
- exactly one blank line between groups, one between days.

The printer is deterministic: it writes tokens in a fixed order and never
reflects any Plan_Parse_Warning content. This is what enables
**parse → print → parse = parse** (R10 AC1).

### 5.8 Offline Guarantee

`text_plan_parser.dart` and `plan_pretty_printer.dart` import only
`dart:core` and the freezed/equatable packages. They are covered by
`tool/check_offline_imports.sh` (Section 13).

---

## 6. Plan_Draft Model

Lives in `lib/modules/program_management/services/text_plan/plan_draft.dart`.
Independent of the editor `ProgramDraft` — this is the parser's output
shape.

```dart
@freezed
abstract class PlanDraft with _$PlanDraft {
  const factory PlanDraft({
    required String programName,
    required List<PlanDraftWorkoutDay> workoutDays,
  }) = _PlanDraft;
  factory PlanDraft.fromJson(...) => ...;
}

@freezed
abstract class PlanDraftWorkoutDay with _$PlanDraftWorkoutDay {
  const factory PlanDraftWorkoutDay({
    required String name,
    required List<PlanDraftGroup> groups,
  }) = _PlanDraftWorkoutDay;
}

@freezed
abstract class PlanDraftGroup with _$PlanDraftGroup {
  const factory PlanDraftGroup({
    required ExerciseGroupKind kind,
    required List<PlanDraftExercise> exercises,
  }) = _PlanDraftGroup;
}

@freezed
abstract class PlanDraftExercise with _$PlanDraftExercise {
  const factory PlanDraftExercise({
    required String draftId,              // stable within this PlanDraft so warnings can reference it
    required String name,
    required MeasurementType measurementType,
    required ExerciseMetadata metadata,   // empty unless the parser learns metadata later
    required int? plannedRestSeconds,
    required List<PlanDraftSet> sets,
  }) = _PlanDraftExercise;
}

@freezed
abstract class PlanDraftSet with _$PlanDraftSet {
  const factory PlanDraftSet({
    required PlannedSetValues values,   // typed, not raw text — parser only produces well-formed values
  }) = _PlanDraftSet;
}
```

`PlanDraftToAggregate.convert(PlanDraft, Uuid idGenerator, Clock clock)`
returns a `ProgramDraft` with fresh UUIDs, ready for the preview screen.
The conversion is pure, takes injectable `Uuid` and `AppClock` so tests can
pin outputs.

---

## 7. Persistence Integration and the `plannedRestSeconds` Extension

R6 requires that `plannedRestSeconds` survives into every `SessionSnapshot`.
The current `Exercise` domain model does not carry the field, so this spec
adds it.

### 7.1 Domain Model Change

```dart
// lib/modules/domain/models/exercise.dart (ADD plannedRestSeconds)
factory Exercise({
  required String id,
  required String exerciseGroupId,
  required int position,
  required String name,
  required MeasurementType measurementType,
  required ExerciseMetadata metadata,
  int? plannedRestSeconds,                 // NEW — 0..3600 or null
  required List<WorkoutSet> sets,
  required DateTime createdAt,
  required DateTime updatedAt,
  required int schemaVersion,
}) = _Exercise;
```

Invariant added in the private `Exercise._()` body:

```dart
if (plannedRestSeconds != null &&
    (plannedRestSeconds < 0 || plannedRestSeconds > 3600)) {
  throw ValidationError(
    entityId: id,
    invariant: 'plannedRestSeconds_out_of_range',
    message: 'plannedRestSeconds must be in [0, 3600], got $plannedRestSeconds',
  );
}
```

### 7.2 Drift Table Change

```dart
// lib/modules/persistence/database/tables.dart (ADD column)
class Exercises extends Table {
  // ... existing columns ...
  IntColumn get plannedRestSeconds => integer().nullable()(); // NEW
  // ...
}
```

### 7.3 Drift Schema Version Bump and Migration

```dart
// lib/core/schema_versions.dart
abstract final class SchemaVersions {
  static const int drift  = 2;   // was 1
  static const int domain = 2;   // was 1
}
```

```dart
// lib/modules/persistence/database/migrations.dart
class AppMigrations {
  static Future<void> onUpgrade(Migrator m, int from, int to) async {
    if (from < 2) {
      await m.addColumn(m.database.exercises, m.database.exercises.plannedRestSeconds);
    }
  }
}
```

Pre-existing rows get `NULL` automatically. Every other `Exercise` field is
untouched (R6 AC6).

### 7.4 Repository Contract Update

`ProgramRepository.createExercise` gets a new optional named parameter:

```dart
Future<Exercise> createExercise({
  required String exerciseGroupId,
  required String name,
  required MeasurementType measurementType,
  ExerciseMetadata metadata = ExerciseMetadata.empty,
  int? plannedRestSeconds,                                  // NEW
});
```

`updateExercise` already takes a full `Exercise` by value, so it picks up
the new field automatically once the freezed model carries it. No breaking
signature change.

### 7.5 Canonical JSON Impact

`Exercise.toJson` produced by `json_serializable` already emits keys in
declaration order; `CanonicalJson.encode` re-sorts them
lexicographically. Adding `plannedRestSeconds` as a nullable field with
`include_if_null: false` (already the global setting) means:

- **New** Exercise rows that carry a non-null value will include the key in
  canonical JSON.
- **New** Exercise rows with `null` will **not** include the key, matching
  the old format.
- **Pre-existing** Session snapshots were serialized before migration, so
  their `canonicalJson` does not mention `plannedRestSeconds` and their
  `sha256Hash` stays identical after migration (R11 AC3, AC4, AC8).

### 7.6 Session Snapshot Impact Summary

| Scenario | snapshot.canonicalJson | snapshot.sha256Hash |
|---|---|---|
| Legacy session, read after migration | unchanged bytes | unchanged |
| New session started after migration, exercise has null rest | key absent | matches legacy format |
| New session started after migration, exercise has 90s rest | key present | new (expected) |

---

## 8. Atomic Save of Pasted Plans (R9 AC3, AC7)

`ProgramRepository` does not expose a single "save aggregate" method. We
add one:

```dart
// lib/modules/domain/repositories/program_repository.dart
abstract class ProgramRepository {
  // ... existing methods ...
  /// Persists an entire Program aggregate in a single transaction.
  /// On any domain-level failure, no partial writes remain.
  Future<Program> saveProgramAggregate(ProgramAggregate aggregate);
}
```

```dart
// lib/modules/program_management/models/program_aggregate.dart
@freezed
abstract class ProgramAggregate with _$ProgramAggregate {
  const factory ProgramAggregate({
    required String name,
    required List<WorkoutDayAggregate> workoutDays,
  }) = _ProgramAggregate;
}
// ... nested aggregates mirror Program → WorkoutDay → ExerciseGroup → Exercise → WorkoutSet
```

**Drift implementation** — one `transaction` block that inserts rows in
dependency order; any exception rolls back. No session tables are touched
(R11 AC2).

**Sequenced-writes fallback (if transaction boundary is unavailable)** —
The module calls `createProgram`, `createWorkoutDay`, … in order, and on any
failure it runs a compensating `deleteProgram` (which cascades via the
foreign-key rules in `tables.dart`). This path is documented but the
transactional method is strongly preferred.

The Plan_Preview save path (R9 AC3) uses `saveProgramAggregate` and
navigates to `ProgramListScreen` on success; on failure it rolls back and
shows a banner with the user's edits preserved (R9 AC7).

---

## 9. External Link Launcher (R7)

```dart
// lib/modules/program_management/services/external_link_launcher.dart
abstract interface class ExternalLinkLauncher {
  Future<ExternalLinkResult> launch(Uri url);
}

sealed class ExternalLinkResult {
  const ExternalLinkResult();
}
final class ExternalLinkOpened   extends ExternalLinkResult { const ExternalLinkOpened(); }
final class ExternalLinkFailure  extends ExternalLinkResult {
  const ExternalLinkFailure(this.reason);
  final String reason;
}
```

**Concrete implementation** uses `package:url_launcher` (to be added).
YouTube host handling:

```dart
class UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher {
  static const _youtubeHosts = {'youtube.com', 'youtu.be', 'm.youtube.com', 'www.youtube.com'};

  @override
  Future<ExternalLinkResult> launch(Uri url) async {
    if (_youtubeHosts.contains(url.host.toLowerCase())) {
      final appUri = _toYoutubeAppUri(url);
      if (await canLaunchUrl(appUri)) {
        final ok = await launchUrl(appUri, mode: LaunchMode.externalApplication);
        if (ok) return const ExternalLinkOpened();
      }
      // fall through to browser
    }
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    return ok ? const ExternalLinkOpened() : const ExternalLinkFailure('launchUrl_returned_false');
  }
}
```

`url_launcher` is a Flutter-team package that wraps platform intents; it
does **not** pull in `http`, `dio`, or any other forbidden dependency.
Section 13 codifies this.

The launcher is the only outbound boundary in the module (R13 AC4).

---

## 10. Validation Strategy

All validation lives in one pure-Dart file:

```dart
// lib/modules/program_management/services/program_validation.dart
abstract final class ProgramValidation {
  static ProgramNameValidation validateProgramName(String raw);   // 1..120 trim (R2), 1..100 edit (R3) — two variants
  static ExerciseNameValidation validateExerciseName(String raw); // 1..80 (R5)
  static WorkoutDayNameValidation validateWorkoutDayName(String raw); // 1..100 (R4)
  static RepBasedSetValidation validateRepBasedSet(String weight, String reps);   // 0..1000@0.5, 0..999 (R5, R15)
  static TimeBasedSetValidation validateTimeBasedSet(String duration);             // 0..3600 (R5, R15)
  static PlannedRestValidation validatePlannedRest(String raw);   // 0..3600, nullable (R6)
  static VideoUrlValidation validateVideoUrl(String? raw);        // http/https, 0..2048 (R7)
  static NotesValidation validateNotes(String? raw);              // 0..2000 (R7)
  static SetCountValidation validateSetCount(int count);          // 1..20 (R5 AC8)
}
```

Every return type is a sealed freezed union `Valid(value)` / `Invalid(reason)`
so BLoCs pattern-match on the result and emit concrete states.

**Message content** is supplied by a separate `DomainErrorPresenter`
(Section 11); `ProgramValidation` only computes the predicate and the
error code.

### 10.1 Mapping R15 to Functions

| R15 AC | Function | Invalid reason |
|---|---|---|
| AC3 | `validateRepBasedSet` | `RepBasedInvalid.weightNegative`, `RepBasedInvalid.weightNotHalfKg` |
| AC4 | `validateTimeBasedSet` | `TimeBasedInvalid.durationNegative`, `TimeBasedInvalid.durationNotWhole` |
| AC5 | `validateRepBasedSet` | `RepBasedInvalid.repsNegative`, `RepBasedInvalid.repsNotWhole` |
| AC6 | `validatePlannedRest` | `PlannedRestInvalid.negative`, `PlannedRestInvalid.notWhole`, `PlannedRestInvalid.outOfRange` |

---

## 11. Error Surfacing

```dart
// lib/modules/program_management/services/domain_error_presenter.dart
abstract final class DomainErrorPresenter {
  static PresentedMessage present(DomainError error) {
    return switch (error) {
      ValidationError(:final entityId, :final invariant, :final message) =>
        PresentedMessage(
          title: 'Invalid value',
          body: '$invariant ($entityId): $message', // R15 AC1: verbatim
        ),
      NotFoundError(:final entityType, :final id) =>
        PresentedMessage(title: '$entityType not found', body: id),
      ImmutabilityError(:final sessionId, :final message) =>
        PresentedMessage(title: 'Historical record protected', body: '$message (session $sessionId)'),
      OrderingError(:final sessionExerciseId, :final currentState, :final message) =>
        PresentedMessage(title: 'Out-of-order edit', body: '$message [$sessionExerciseId / $currentState]'),
      VersionMismatchError(:final persisted, :final expected) =>
        PresentedMessage(title: 'Database newer than app', body: 'persisted v$persisted > expected v$expected'),
      DeserializationError(:final field, :final discriminator, :final message) =>
        PresentedMessage(title: 'Data could not be read', body: '$field${discriminator == null ? '' : '/$discriminator'}: $message'),
    };
  }
}
```

**`PlanParseErrorBanner`** renders the parser error as:

```
┌─────────────────────────────────────────────────────┐
│ ⚠ Couldn't parse line 7, column 3                    │
│    <orphan_set_line>                                 │
│    This line looks like a set but no exercise is     │
│    open. Add an exercise name on the previous line.  │
└─────────────────────────────────────────────────────┘
```

The paste surface retains `state.text` verbatim (R15 AC2); the banner
highlights the offending line by splitting the text on `\n`/`\r\n` and
wrapping line `error.line` in a highlighted `RichText`.

---

## 12. Correctness Properties (PBT)

Tests live under `test/modules/program_management/`. Generators live under
`test/support/program_management_generators.dart`.

### 12.1 Property Suite

| Req | Property | Test file | Strategy |
|---|---|---|---|
| R10 AC1 | parse → print → parse = parse | `text_plan/parse_print_roundtrip_property_test.dart` | Generate `PlanDraft`; pretty-print; parse; assert `==` (warnings excluded) |
| R10 AC2 | parser determinism | `text_plan/parser_determinism_property_test.dart` | For generated `Plan_Text`, invoke parser twice in same isolate; assert equal results |
| R10 AC3 | tolerance invariants | `text_plan/parser_tolerance_property_test.dart` | For a canonical Plan_Text P, apply random whitespace/case/line-ending transformations; assert parsed draft is `==` |
| R10 AC4 | save → load → print → parse equivalence | `text_plan/save_load_roundtrip_property_test.dart` | Generate `PlanDraft`; save via `AggregateSaver` on in-memory `AppDatabase`; load via `ProgramRepository`; convert back to `PlanDraft`; pretty-print; parse; assert `==` |
| R10 AC5 | error determinism | `text_plan/parser_error_determinism_property_test.dart` | Generate unparseable `Plan_Text`; invoke parser multiple times; assert identical `PlanParseError` (line, column, code) |

### 12.2 Generators

```dart
// test/support/program_management_generators.dart
PlanDraft anyPlanDraft(Random rng) { ... }     // 1..4 days, 1..5 groups, 1..6 exercises, 1..6 sets, mix of measurement types
String anyPlanText(Random rng) => PlanPrettyPrinter.print(anyPlanDraft(rng));
String anyUnparseablePlanText(Random rng) { ... } // deliberately produces lines that match no classification rule
String anyWhitespaceVariation(String input, Random rng) { ... } // randomly re-runs WS, flips case on keywords, swaps line endings
```

Use the millisecond-offset pattern from `flutter-tooling.md` for any date
generation; use `rng.nextInt(max)` only with `max <= 2^32`.

### 12.3 Cross-BLoC Properties

- **`ProgramEditorBloc` determinism** — any sequence of draft events applied
  in the same order against the same initial state produces the same final
  state.
- **`AggregateSaver` idempotence** — saving the same `ProgramAggregate`
  twice against a clean DB produces Programs that are equal under freezed
  `==` except for ids, timestamps, and `schemaVersion`.

---

## 13. Offline-First and Import Allowlist

### 13.1 Forbidden Imports (inside the module)

- `package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`,
  `package:socket_io_client`.
- `dart:io` classes `HttpClient`, `HttpServer`, `Socket`, `ServerSocket`,
  `RawSocket`, `SecureSocket`, `SecureServerSocket`.
- `package:drift/*`, `package:drift_flutter/*`, `package:sqlite3/*`.
- Any `*.g.dart` file located under `lib/modules/persistence/`.
- `AppDatabase`, `NativeDatabase`, `driftDatabase`, `GeneratedDatabase`.

### 13.2 `tool/check_offline_imports.sh` Extension

Extend the existing script so it additionally scans
`lib/modules/program_management/` with the forbidden list above. The
script exits non-zero and prints `<file>:<line>:<offending symbol>` for
every violation (R12 AC5).

### 13.3 New Dependencies

| Package | Version | Forbidden import check |
|---|---|---|
| `flutter_bloc` | `^9.1.1` | Clean — no network, no `dart:io` |
| `equatable` | `^2.0.7` | Clean |
| `url_launcher` | `^6.3.1` | Clean — platform channels only; no `http`, `dio`, or socket APIs. The launcher is the designated single outbound boundary (R13 AC4). |
| `bloc_test` (dev) | `^10.0.0` | Test-only |

No networking package is introduced.

---

## 14. Testing Plan

### 14.1 BLoC Unit Tests (`bloc_test`)

| BLoC | Representative scenarios |
|---|---|
| `ProgramListBloc` | Empty DB → `Loaded([])`; delete confirms; delete cancels; load failure → `Failure`; retry transitions to `Loading`→`Loaded`; deterministic tie-break sort |
| `ProgramEditorBloc` | Create mode: name disable/enable at 0/1/120/121 chars; save creates program then workout days; error keeps draft. Edit mode: not-found path; rename > 100 chars rejected; reorder persists |
| `WorkoutDayEditorBloc` | Cardinality violation emits `GroupValidationError`; group save persists via `updateExerciseGroup`; non-validation error retains edits |
| `ExerciseEditorBloc` | Measurement-type change requires confirm; confirm reinitializes sets; cancel preserves sets; add past 20 rejected; delete below 1 rejected; video URL invalid blocks save |
| `PlanImportBloc` | Empty text → `empty_input` error; valid text → `Success(draft, warnings)`; determinism property |
| `PlanPreviewBloc` | Save success navigates; transactional failure rolls back; validation failure retains draft |

### 14.2 Widget Tests

Each screen has at least:

- **happy path** (list loads, editor accepts input, exercise editor saves);
- **validation path** (invalid input shows banner, offending value preserved);
- **failure path** (repository error shows `DomainErrorBanner`, retry works).

### 14.3 Parser Tests

- Golden corpus under `test/modules/program_management/text_plan/golden/`
  containing coach-paste samples (rep-based only, time-based only, mixed,
  with supersets, with rest tokens in both `s` and `m`, with recoverable
  warnings).
- Five PBT suites from Section 12.

### 14.4 Migration Tests

`test/integration/exercise_planned_rest_migration_test.dart` seeds a
schema-v1 DB using Drift's migration-testing utilities, runs the upgrade,
and asserts:

- every pre-existing row is preserved;
- `planned_rest_seconds` is `NULL` for every migrated row;
- `Exercise.toJson` round-trips (with and without `plannedRestSeconds`).

### 14.5 CI Wiring

The existing `tool/ci.sh` sequence (imports → codegen → analyze → test)
covers the new code automatically. No new script is needed beyond the
`check_offline_imports.sh` extension.

---

## 15. Open Questions and Design Decisions

1. **Paste surface vs preview routing** — we keep them as separate routes
   (`/programs/import` and `/programs/import/preview`). A single-scaffold
   approach was considered but rejected: state management of a multi-stage
   form conflates two distinct BLoCs. Each route owns its own BLoC.

2. **Program name location on the editor** — the program name lives in the
   `AppBar` as an inline-editable `TextField` with trailing checkmark on
   focus loss. This gives it prime real estate and keeps the body for the
   workout-day list. Alternative (name as the first body field) was
   rejected for one-handed ergonomics.

3. **Measurement-type change when planned sets are empty** — we still show
   the confirmation prompt (R5 AC5) even if `sets.length == 0`, because
   the user could have typed raw input in an in-memory draft that hasn't
   been persisted; retaining the prompt keeps the UX predictable.

4. **Workout-day append-position** — R4 AC2 mandates append-at-end. We do
   not support drag-to-position-on-create; the user reorders after adding.
   This keeps the add gesture one-tap.

5. **Parser rest-token ordering** — when a planned-set line contains
   multiple rest-like tokens, the last one wins. Rationale: matches how
   humans mentally scan "4x8 100kg 2m" (the last suffix is the rest). The
   earlier ones emit warnings.

6. **`schemaVersion` bump** — we bump both `drift` and `domain` to `2`.
   Existing aggregates in the DB are fine (migration sets `NULL`); newly
   written aggregates carry `schemaVersion=2`.

7. **`saveProgramAggregate` contract addition** — this adds a method to
   the domain-layer `ProgramRepository`. Because the domain spec is
   already in `COMPLETE` status, we are extending its public API. Ledger
   entry: this spec owns the new method; `core-domain-and-persistence`'s
   design doc should be updated to reference the extension when the
   next domain-wide revision ships.

8. **`url_launcher` as the designated boundary** — committed. If the host
   team ever wants to remove it, the replacement must also be a
   platform-channel-only package; never an HTTP client.

---

## 16. Requirement Coverage Matrix

| Requirement | Design elements |
|---|---|
| R1 Program List Screen | §2.2 ProgramListScreen, §3.1 ProgramListBloc, sort R1 AC2 |
| R2 Create From Empty Form | §3.2 ProgramEditorBloc create-mode, §4 ProgramDraft, §8 save path |
| R3 Edit Existing Program | §3.2 ProgramEditorBloc edit-mode, §10 ProgramValidation (name 1..100) |
| R4 Workout Day Editor | §3.3 WorkoutDayEditorBloc, §4 draft model, §10 WorkoutDayName validation |
| R5 Exercise Authoring | §3.4 ExerciseEditorBloc, §10 RepBased/TimeBased validation, §4 planned-set count 1..20 |
| R6 Planned Rest | §7 domain + Drift extension, §10 PlannedRest validation |
| R7 Exercise Metadata | §9 ExternalLinkLauncher, §10 VideoUrl/Notes validation |
| R8 Text-Plan Parser | §5 parser grammar + classifier + errors |
| R9 Plan Preview and Save | §2.2 PlanPreviewScreen, §3.6 PlanPreviewBloc, §8 atomic save |
| R10 Parser Properties | §5.7 pretty-printer, §12 PBT suites |
| R11 Template Integrity | §8 no Session writes; §7.6 snapshot byte stability |
| R12 Repository-Only Access | §1.3 DI, §13 import allowlist |
| R13 Offline Isolation | §5.8, §9, §13 |
| R14 Module Conventions | §1.2 folder structure, `flutter analyze` gate in §14.5 |
| R15 Error Surfaces | §10 ProgramValidation, §11 DomainErrorPresenter + banners |
