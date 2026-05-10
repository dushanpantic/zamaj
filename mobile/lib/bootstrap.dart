import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:zamaj/app.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase(driftDatabase(name: 'zamaj'));
  const clock = Clock();
  final programRepo = DriftProgramRepository(db: db, clock: clock);
  final sessionRepo = DriftSessionRepository(
    db: db,
    programRepository: programRepo,
    clock: clock,
  );
  runApp(MainApp(programRepo: programRepo, sessionRepo: sessionRepo));
}
