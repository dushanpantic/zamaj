# Flutter App - Init Guide

Starter guide for a new offline-only Flutter app with a clean separation
between UI and state. No backend, no Firebase, no internationalization.

---

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # Root MaterialApp widget
├── bootstrap.dart            # Async init, then runApp
├── building_blocks/          # Generic, reusable widgets
│   └── widgets/
│       ├── state/            # Loading / empty / error wrappers
│       └── display/
├── core/                     # Infrastructure
│   ├── app_colors.dart
│   ├── app_theme.dart
│   ├── app_error.dart        # Typed error sealed class
│   └── bloc/
│       └── bloc_observer.dart
├── modules/                  # Feature modules
│   └── <feature>/
│       ├── bloc/
│       │   ├── <feature>_bloc.dart
│       │   ├── <feature>_event.dart
│       │   ├── <feature>_state.dart
│       │   └── bloc.dart     # Barrel export
│       ├── models/
│       ├── services/         # Business logic
│       ├── repository/       # Data source seam (optional)
│       ├── screens/
│       ├── widgets/
│       └── <feature>.dart    # Barrel export
└── navigation/
    ├── app_router.dart       # GoRouter setup (if using)
    └── route_constants.dart
```

---

## Conventions

### BLoC pattern
- Three files per BLoC: `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- One barrel: `bloc.dart`
- Events and states are **sealed classes** extending `Equatable`
- Services are injected into BLoCs via constructor
- BLoCs know nothing about UI; screens subscribe via `BlocBuilder` / `BlocListener`

### Data layer
- **Service** = business logic, single responsibility
- **Repository** = aggregates services and data sources, exposes a domain API to BLoCs
- Swap data sources (sqflite, drift, isar, shared_preferences) behind the repository without touching BLoCs

### Module organization
- One folder per feature under `lib/modules/`
- Each module has a barrel export file (`<feature>.dart`) for its public API
- Module-specific widgets stay in the module; truly generic widgets go to `building_blocks/`

### Dart style
- 80-char line length
- PascalCase classes, camelCase members, snake_case filenames
- `const` constructors where possible
- Null-safe; avoid `!` unless guaranteed non-null
- Prefer small private Widget classes over helper methods

---

## Dependencies

Start minimal. Add more only when needed.

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7

  # DI (optional - constructor injection or get_it also work)
  provider: ^6.1.2

  # Navigation (skip if single-flow app; Navigator is enough)
  go_router: ^17.0.1

  # Storage
  shared_preferences: ^2.2.3
  # Pick one if you need structured local data:
  # sqflite: ^2.3.3    # SQL, mature, zero codegen
  # drift: ^2.20.0     # typed SQL, codegen
  # isar: ^3.1.0       # NoSQL, fast
  # hive: ^2.2.3       # NoSQL, simple

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^10.0.0
```

---

## First Steps

1. `flutter create <app_name>` with the platforms you need.
2. Enable `flutter_lints` in `analysis_options.yaml`.
3. Create the folder skeleton above.
4. Write a minimal `bootstrap.dart`:
   ```dart
   Future<void> bootstrap() async {
     WidgetsFlutterBinding.ensureInitialized();
     Bloc.observer = AppBlocObserver();
     // open DB / load prefs here
     runApp(const MyApp());
   }
   ```
5. Build one module end-to-end (e.g. `home`) following the pattern above,
   with a repository backed by a local data source. That becomes the template
   for every other module.

---

## Reference Skeletons

### `<feature>_event.dart`
```dart
import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}
```

### `<feature>_state.dart`
```dart
import 'package:equatable/equatable.dart';

sealed class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

final class HomeLoaded extends HomeState {
  const HomeLoaded(this.items);
  final List<String> items;
  @override
  List<Object?> get props => [items];
}

final class HomeFailure extends HomeState {
  const HomeFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
```

### `<feature>_bloc.dart`
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required HomeRepository repository})
      : _repository = repository,
        super(const HomeInitial()) {
    on<HomeStarted>(_onStarted);
    on<HomeRefreshed>(_onStarted);
  }

  final HomeRepository _repository;

  Future<void> _onStarted(HomeEvent event, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    try {
      final items = await _repository.loadItems();
      emit(HomeLoaded(items));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }
}
```

### `bloc/bloc.dart` (barrel)
```dart
export 'home_bloc.dart';
export 'home_event.dart';
export 'home_state.dart';
```

### `bloc_observer.dart`
```dart
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('${bloc.runtimeType} error', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
```

---

## Guardrails

- Keep BLoCs free of Flutter imports other than `flutter_bloc`.
- Keep repositories free of UI concerns.
- Don't use `print`; use `log` from `dart:developer`.
- Don't store sensitive data in `shared_preferences`; use `flutter_secure_storage` if and when auth is added.
- Add a barrel export for every new module.
- Add tests for BLoCs with `bloc_test` as you go.
