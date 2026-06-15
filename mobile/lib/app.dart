import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/services/share_plus_share_service.dart';
import 'package:zamaj/modules/export/services/share_service.dart';
import 'package:zamaj/navigation/app_router.dart';
import 'package:zamaj/navigation/app_routes.dart';

class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.programRepo,
    required this.sessionRepo,
    required this.exerciseLibraryRepo,
    required this.sessionFlowEngine,
    required this.clock,
  });

  final ProgramRepository programRepo;
  final SessionRepository sessionRepo;
  final ExerciseLibraryRepository exerciseLibraryRepo;
  final SessionFlowEngine sessionFlowEngine;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProgramRepository>.value(value: programRepo),
        RepositoryProvider<SessionRepository>.value(value: sessionRepo),
        RepositoryProvider<ExerciseLibraryRepository>.value(
          value: exerciseLibraryRepo,
        ),
        RepositoryProvider<SessionFlowEngine>.value(value: sessionFlowEngine),
        RepositoryProvider<Clock>.value(value: clock),
        RepositoryProvider<ExternalLinkLauncher>(
          create: (_) => const UrlLauncherExternalLinkLauncher(),
        ),
        RepositoryProvider<ShareService>(
          create: (_) => const SharePlusShareService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.shell,
      ),
    );
  }
}
