# Structure

## Top-level layout

```
mobile/
├── lib/                     # App source
├── test/                    # Unit, property, integration tests
├── tool/                    # CI and maintenance scripts
├── android/ ios/ macos/
├── linux/ windows/ web/     # Platform shells (Flutter defaults)
├── analysis_options.yaml    # Strict lints
├── build.yaml               # Codegen scopes (freezed / json / drift)
├── pubspec.yaml
├── mvp-design-doc.md        # Product brief
├── init.md                  # General Flutter app conventions reference
└── README.md
```

## `lib/` — source layout

```
lib/
├── main.dart                        # Flutter entry point
├── core/                            # Cross-cutting infrastructure (no I/O, no networking)
│   ├── app_error.dart               # Typed error sealed class
│   ├── canonical_json.dart          # Stable JSON encoding for hashing/goldens
│   ├── clock.dart                   # Injectable time source
│   ├── deserialization.dart         # Shared JSON decode helpers
│   └── schema_versions.dart         # Snapshot and DB schema version constants
└── modules/
    ├── domain/                      # Pure domain: no Flutter, no Drift, no I/O
    │   ├── domain.dart              # Barrel export
    │   ├── errors.dart              # Domain-level typed errors
    │   ├── models/                  # Freezed value objects and aggregates
    │   └── repositories/            # Abstract repository contracts
    └── persistence/                 # Drift-backed implementation of domain repos
        ├── persistence.dart         # Barrel export
        ├── database/                # Drift database, tables, migrations, utils
        ├── mappers/                 # Domain ↔ Drift row conversions
        └── repositories/            # Concrete Drift repository implementations
```

### Layer rules

- **`core`** — standalone utilities. No dependency on `modules/`. No networking, no `dart:io` socket APIs.
- **`domain`** — pure Dart. Depends only on `core` and allowed packages (`freezed_annotation`, `json_annotation`, `uuid`, `clock`, `crypto`). Defines repository *interfaces*; never imports Drift, Flutter widgets, or platform channels.
- **`persistence`** — the only layer allowed to use Drift. Implements the repository interfaces from `domain`. Uses `mappers/` to translate between Drift rows and domain models. Must not leak Drift types across its public API.
- **Future UI / BLoC layers** will live under `lib/modules/<feature>/` following the conventions in `init.md` (bloc/, screens/, widgets/, services/ with per-module barrel exports). They may depend on `domain` and `core`, never on `persistence` directly — always go through the repository contract.

### Barrel exports

Every module exposes a barrel file (`domain.dart`, `persistence.dart`). Import through the barrel from outside the module; relative imports within a module are fine. The lint `avoid_relative_lib_imports` is on, so cross-package imports must use `package:zamaj/...`.

## `test/` — test layout

```
test/
├── core/              # Canonical JSON and infra tests (incl. property-based)
├── domain/            # Domain model construction, invariants, repo-contract purity
├── persistence/       # Mapper round-trip tests
├── repository/        # Drift repository behavior (foreign keys, ordering, immutability)
├── integration/       # End-to-end Drift scenarios
├── serialization/     # JSON round-trip, corruption, and golden fixtures
│   └── golden/        # Committed JSON goldens per domain type
└── support/           # Shared test helpers (generators, in-memory DB)
```

Mirror the `lib/` layer naming so a file's home is obvious. Property-based tests use generators from `test/support/generators.dart`.

## `tool/` — scripts

- `ci.sh` — full local CI (import-allowlist → codegen → analyze → test).
- `check_offline_imports.sh` — enforces offline-first isolation on `core`, `domain`, `persistence`.
- `generate_aggregate_goldens.dart` — regenerates committed JSON goldens.

## `.kiro/` — spec and steering

```
.kiro/
├── specs/<feature>/   # requirements.md, design.md, tasks.md, .config.kiro
└── steering/          # Always-on guidance (this file, product, tech, tooling, style)
```

## File naming

- `snake_case.dart` for Dart files.
- Generated siblings: `*.freezed.dart`, `*.g.dart` (committed, not hand-edited).
- Test files end in `_test.dart`.
- One public type per file for domain models; small private helpers may live alongside.
