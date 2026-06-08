import 'dart:developer' as developer;

import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/app.dart';
import 'package:zamaj/core/app_bloc_observer.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_exercise_library_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

const _seedAssetPath = 'assets/exercise_library_seed.json';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  final db = AppDatabase(driftDatabase(name: 'zamaj'));
  const clock = Clock();
  final programRepo = DriftProgramRepository(db: db, clock: clock);
  final sessionRepo = DriftSessionRepository(
    db: db,
    programRepository: programRepo,
    clock: clock,
  );
  final exerciseLibraryRepo = DriftExerciseLibraryRepository(
    db: db,
    clock: clock,
  );
  await _seedCanonicalLibrary(exerciseLibraryRepo);
  final sessionFlowEngine = SessionFlowEngine(repository: sessionRepo);
  runApp(
    MainApp(
      programRepo: programRepo,
      sessionRepo: sessionRepo,
      exerciseLibraryRepo: exerciseLibraryRepo,
      sessionFlowEngine: sessionFlowEngine,
      clock: clock,
    ),
  );
}

/// Idempotently seeds the embedded canonical exercise catalog. Any failure —
/// a missing/corrupt asset, a parse error, a database hiccup — is logged and
/// swallowed so a bad seed can never block app launch.
Future<void> _seedCanonicalLibrary(ExerciseLibraryRepository repository) async {
  try {
    final catalogJson = await rootBundle.loadString(_seedAssetPath);
    final inserted = await CanonicalLibrarySeeder(repository).seed(catalogJson);
    developer.log('Seeded $inserted canonical exercise(s).', name: 'Seed');
  } catch (error, stackTrace) {
    developer.log(
      'Canonical library seeding failed; launching without it.',
      name: 'Seed',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
