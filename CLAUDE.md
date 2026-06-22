# CLAUDE.md

## Project

**Zamaj** — offline-first Flutter workout execution app. Code lives in `mobile/`; run all commands from there.

Sessions capture an immutable **snapshot** of the planned workout at start. The program template is never mutated by in-session edits; completed sessions never change retroactively. Planned and actual values are tracked separately.

**Product context lives in [PRODUCT.md](PRODUCT.md)** — the source of truth for what the app does, who it's for, the user-facing features, and the screens that host them. Read it before any user-facing work.

### Keeping PRODUCT.md current

When a change adds, removes, or renames a user-facing screen or feature, or shifts a pillar or non-goal, update [PRODUCT.md](PRODUCT.md) in the same change. Pure internal refactors (bloc renames, widget moves, repo signature tweaks) do not. When in doubt, update — a slightly-stale doc is worse than a slightly-redundant edit.

## Commands (project-specific only)

```bash
dart run build_runner build --force-jit   # codegen — --force-jit is REQUIRED
dart run build_runner watch --force-jit
tool/check_offline_imports.sh              # offline-first isolation guard
tool/ci.sh                                 # imports → codegen → format → analyze → test
dart run tool/generate_aggregate_goldens.dart  # regenerate JSON goldens
```

- `--force-jit` is required: AOT fails because `sqlite3` 3.x uses Dart native build hooks.
- Do not pass `--delete-conflicting-outputs` (removed in build_runner 2.14, silently ignored).
- Generated files (`*.freezed.dart`, `*.g.dart`) are committed; never hand-edit.

## Architecture

`lib/modules/` splits into `domain/` (pure Dart: freezed models, repo contracts, `SessionFlowEngine`), `persistence/` (Drift tables, migrations, repo impls), and UI feature modules (`program_management/`, `exercise_library/`, `workout_day_picker/`, `workout_overview/`, `focus_mode/`, `export/`, `exercise_progress/`). `lib/core/` is cross-cutting (theme, tokens, clock, canonical_json, schema_versions). `lib/navigation/` routes per-module.

**Layer rules — enforced by `tool/check_offline_imports.sh`:**

- `core`, `domain`, `persistence` must NOT import networking (`dart:io`, `http`, `dio`, `web_socket_channel`, `grpc`, `socket_io_client`).
- UI modules must NOT import `drift`/`drift_flutter`/`sqlite3` or reference `AppDatabase`/`NativeDatabase`/`GeneratedDatabase`/`HttpClient`/`Socket`. UI talks to data only through domain repository contracts.
- `domain` is pure Dart — no Flutter, no Drift, no platform channels.
- Cross-module imports go through barrel files (`domain.dart`, `persistence.dart`, `<feature>.dart`). Use `package:zamaj/...`, not relative imports.

**Session flow:** `SessionFlowEngine` is a stateless orchestrator. Every mutation round-trips through `SessionRepository`, recomputes a `Cursor`, returns a fresh `SessionState`. UI blocs depend on the engine, not on repositories directly for session flow.

**Single active session:** the "one session in progress at a time" rule is a UI guard in `WorkoutDayPickerBloc` only — the domain deliberately permits concurrent sessions (future coach+trainee model). Don't push it into `SessionFlowEngine` as an invariant. `ActiveSessionPolicy` is the source of truth for which in-progress session is "active."

**Replace-exercise is dormant:** the domain (`SessionFlowEngine.replaceExercise`, `ReplacedState`, `SubstituteExercise`, and assembler/view-model render branches) is intentionally kept but the UI/bloc was removed pending a redesign. Don't re-add the Replace UI or "clean up" the dormant domain code without the user.

**Schema versions:** `lib/core/schema_versions.dart` is the single source of truth for both Drift's `schemaVersion` and the `domain` version stamped on every persisted row. Bump deliberately and add a migration under `lib/modules/persistence/database/migrations.dart`.

**Canonical JSON:** `lib/core/canonical_json.dart` produces byte-stable JSON (sorted keys, trimmed numbers, RFC 8259 escapes) used for snapshot hashing and goldens.

## Conventions

### Freezed models with validation

Use a private `._()` constructor with a body + a **non-`const`** redirecting factory:

```dart
@freezed
abstract class MyModel with _$MyModel {
  MyModel._() {
    if (someField < 0) throw ValidationError(...);
  }
  factory MyModel({required int someField}) = _MyModel;
  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

The factory must not be `const` (freezed-generated `const _MyModel(...)` can't call a non-const super). Do not parameterise `._({...})` — json_serializable targets the public factory's signature. `explicit_to_json: true` is set globally in `build.yaml`.

### Coach-marks / first-run tips

Suppress repeat display with a per-app-process `static bool` flag (the tip re-appears after each cold start), as in `workout_day_editor_screen.dart`, `workout_overview_loaded_body.dart`, `session_detail_screen.dart`. Do not reach for `shared_preferences` — once-ever persistence is deferred to a future cross-screen refactor that covers every coach-mark at once.

### UI tokens (mandatory under `lib/modules/**/screens|widgets/`, `lib/building_blocks/`)

No hard-coded pixels, no `Color(0x...)` literals.

- Colors: `Theme.of(context).appColors` (extension in `lib/core/app_theme.dart`). Never import `AppColors.dark`/`AppColors.light` directly.
- Spacing/radius: `AppSpacing.xs..xxxl`, `AppRadius.sm|md|lg|pill`. Tap targets ≥ `AppSpacing.touchMin` (48 dp).
- Typography: `Theme.of(context).textTheme.*`; use `AppTypography.standard.numeric` / `numericLarge` for any numeric readout so tabular figures don't jitter.
- Semantic colors: `planned`/`actual`, `exerciseCompleted|Partial|Skipped|Replaced`, `restTimer`. Add new semantic fields to `AppColors` (both palettes) rather than one-off values.

### In-session sweaty-hands ergonomics (`workout_overview/`, `focus_mode/`)

These two modules are used live in the gym with wet hands — `touchMin` (48 dp) is the floor, not the target. When adding or editing controls under `lib/modules/workout_overview/**` or `lib/modules/focus_mode/**`:

- Step / counter buttons: **64×64 dp** minimum, label at `AppTypography.standard.actionLabel` (18 px, w700).
- Numeric value inputs (the value the user is logging): **`numericLarge`** (36 px).
- Primary action buttons (LOG SET, SAVE, FOCUS): **≥ 56 dp tall**, `actionLabel` text style.
- When two counters would otherwise share a row, **stack vertically** rather than crushing tap targets below ~56 dp wide.
- A few controls are **deliberately compact exceptions** to this floor (e.g. the rest-timer strip, the undo row). Each is marked with an in-code comment explaining why — respect those comments; don't "fix" them back up.

Outside these two modules (program management, day picker, settings), the normal `touchMin` (48 dp) is fine — this rule is specifically about the live-session surface.

### Tests

Scope is **domain, persistence, and pure UI logic** — blocs, services, and assemblers under `test/modules/**`, written as plain `flutter_test` `test()` (+ `FakeSessionRepository`). Still no `bloc_test` package and no Flutter widget tests; verify actual widgets (menus, panels, render) by inspection. Bloc tests must earn their place: cover bloc-only orchestration (draft/optimistic state, timers/tickers, transient-vs-terminal error surfacing, UI-only guards like single-active-session) — never re-prove engine/domain behavior the domain suite already covers. Layout mirrors `lib/` under `test/{core,domain,persistence,repository,serialization,modules}`. Property tests use `test/support/generators.dart`. Drift end-to-end tests live in `test/integration/`; use `makeInMemoryDatabase()` from `test/support/in_memory_app_database.dart`. `Random.nextInt(max)` requires `max <= 2^32` — for dates, use a base timestamp + millisecond offset.
