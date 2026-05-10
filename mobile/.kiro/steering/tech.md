# Tech

## Stack

- **Flutter** (Dart SDK `^3.10.4`) — mobile app, `uses-material-design: true`.
- **Drift** (`drift`, `drift_flutter`, `drift_dev`) — typed SQLite persistence with code generation.
- **Freezed** (`freezed`, `freezed_annotation`) — immutable domain models with copy/equality/serialization.
- **json_serializable** — JSON encoding/decoding for domain models.
- **build_runner** — runs freezed, json_serializable, and drift_dev codegen.
- **uuid** — domain entity identifiers.
- **clock** — injectable time source for deterministic tests.
- **crypto** — content hashing for snapshots and aggregate integrity.
- **path**, **path_provider** — filesystem paths for the SQLite database.

## Dev tooling

- `flutter_lints` plus a strict `analysis_options.yaml` (strict-casts, strict-inference, strict-raw-types, no `print`, single quotes, const-preferred, no relative `lib/` imports).
- `flutter_test` for unit, property-based, and integration tests.

## Code generation

Freezed and json_serializable generate for `lib/modules/domain/models/**.dart`. Drift generates for `lib/modules/persistence/database/app_database.dart` and `tables.dart`. See `build.yaml` for scope. Generated files (`*.freezed.dart`, `*.g.dart`) are committed.

`json_serializable` runs with `explicit_to_json: true`, `include_if_null: false`, `checked: true` — no per-class annotation needed for nested freezed types.

## Offline-first isolation

The following layers must NEVER import networking packages or `dart:io` HTTP/socket APIs:

- `lib/core/`
- `lib/modules/domain/`
- `lib/modules/persistence/`

Enforced by `tool/check_offline_imports.sh` (part of CI). Forbidden imports include `dart:io`, `package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`, `package:socket_io_client`.

## Common commands

Run from the repo root (`mobile/`).

```bash
# Code generation (freezed + json_serializable + drift)
dart run build_runner build --force-jit

# Watch mode during active codegen work
dart run build_runner watch --force-jit

# Static analysis
flutter analyze

# Full test suite
flutter test

# Offline-first import guard
bash tool/check_offline_imports.sh

# Full CI sequence (imports check → codegen → analyze → test)
bash tool/ci.sh
```

**Do not** pass `--delete-conflicting-outputs` — removed in build_runner 2.14 and silently ignored.

**Always** use `--force-jit` for build_runner; AOT compilation breaks when `sqlite3` native hooks are in the tree.

## Freezed conventions

- Models with runtime validation use a private `._()` constructor with a body, paired with a **non-const** redirecting factory (see `.kiro/steering/flutter-tooling.md` for the exact pattern).
- Use `copyWith` rather than mutation.
- Union types via `@freezed` sealed hierarchies are the norm for enums with data (e.g. `ExerciseState`, `MeasurementType`).

## Test strategy

**Current scope: domain layer only.** Do not write BLoC tests, widget tests, or screen tests. Only the following test categories are in scope for now:

- **Unit tests** per layer under `test/core`, `test/domain`, `test/persistence`, `test/repository`, `test/serialization`.
- **Integration tests** under `test/integration` exercise the Drift DB end-to-end (foreign keys, version mismatch, soft refs).
- **Property-based tests** (e.g. `test/core/canonical_json_property_test.dart`) using generators in `test/support/generators.dart`.
- **Golden fixtures** for JSON serialization under `test/serialization/golden/`. Regenerate via `tool/generate_aggregate_goldens.dart`.
- **In-memory DB** helper lives at `test/support/in_memory_app_database.dart`.

`bloc_test` is not a dependency. Do not add it.

## Random ranges in tests

`Random.nextInt(max)` requires `max <= 2^32`. For date generation use a base-date + millisecond-offset pattern (see `flutter-tooling.md`).
