# zamaj

An offline-first Flutter workout execution app.

## Core domain and persistence

The foundational domain model and Drift-backed SQLite persistence layer lives under:

```
lib/core/          — infrastructure utilities (clock, schema versions, canonical JSON)
lib/modules/domain/       — pure domain types and repository contracts
lib/modules/persistence/  — Drift tables, mappers, and concrete repositories
```

### Running code generation

```bash
dart run build_runner build --force-jit
```

The `--force-jit` flag is required on this toolchain because AOT compilation of
build scripts is not supported in the current environment. Generated files
(`*.g.dart`, `*.freezed.dart`) are committed to the repository.

### Running the test suite

```bash
flutter test
```

### Checking offline-first isolation

The domain and persistence layers must never import network packages. Verify
this constraint with:

```bash
bash tool/check_offline_imports.sh
```

The script greps `lib/core/`, `lib/modules/domain/`, and
`lib/modules/persistence/` for forbidden imports (`dart:io` network APIs,
`package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`,
`package:socket_io_client`) and exits non-zero if any are found.

### Running the full CI sequence locally

```bash
bash tool/ci.sh
```

This runs the four steps in the same order as CI: import-allowlist check,
code generation, static analysis, and the test suite.
