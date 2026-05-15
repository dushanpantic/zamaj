import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/app.dart';
import 'package:zamaj/core/app_bloc_observer.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

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
  final sessionFlowEngine = SessionFlowEngine(repository: sessionRepo);
  runApp(
    MainApp(
      programRepo: programRepo,
      sessionRepo: sessionRepo,
      sessionFlowEngine: sessionFlowEngine,
      clock: clock,
    ),
  );
}
