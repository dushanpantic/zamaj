# Flutter Tooling

## Running build_runner

`build_runner` 2.14+ defaults to AOT compilation. This **fails** when `sqlite3` 3.x
is in the dependency tree because that package uses Dart native build hooks, which
`dart compile` refuses to process.

Always run build_runner with `--force-jit`:

```
dart run build_runner build --force-jit
dart run build_runner watch --force-jit
```

Never use `--delete-conflicting-outputs` — it was removed in build_runner 2.14 and
is silently ignored with a warning.

## Freezed — validated models with custom constructors

When a model needs to throw typed errors at construction time (not just `assert`),
use the `ClassName._()` private constructor with a body, paired with a **non-`const`
redirecting factory**:

```dart
@freezed
abstract class MyModel with _$MyModel {
  MyModel._() {
    // validation using this.field — runs after the generated class is constructed
    if (someField < 0) throw ValidationError(...);
  }

  // NOT const — required because ._() has a body, so _MyModel(...) can't be const
  factory MyModel({required int someField, ...}) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}
```

**Why not `const factory`**: freezed generates `const _MyModel(...)` which calls
`super._()`. A `const` constructor cannot call a non-`const` super, so the build
succeeds but the test compiler rejects it with:
`A constant constructor can't call a non-constant super constructor.`

**Why not a parameterised `._({...})`**: `json_serializable` targets the generated
`_MyModel` class and fails with `Cannot populate the required constructor argument: id`
when the private constructor has a different signature than the factory.

The `._()` body accesses fields via `this.field` — these are available because
freezed generates the mixin `_$MyModel` which exposes them before the constructor
body runs.

## Freezed — `toJson` for nested types

`json_serializable` with `explicit_to_json: true` (set globally in `build.yaml`)
handles nested freezed types correctly. No per-class `@JsonSerializable(explicitToJson: true)`
annotation is needed.

## Random date generation in tests

`dart:math` `Random.nextInt(max)` requires `max <= 2^32` (4,294,967,296).

One year in milliseconds is ~31.5 billion — far over the limit. Use a fixed
millisecond offset from a base date:

```dart
DateTime anyUtcDateTime(Random rng) {
  final base = DateTime.utc(2020).millisecondsSinceEpoch;
  final offsetMs = rng.nextInt(4000000000); // ~46 years of range
  return DateTime.fromMillisecondsSinceEpoch(base + offsetMs, isUtc: true);
}
```
