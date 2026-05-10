import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_router.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';

// TODO(task-11.1): Replace with UrlLauncherExternalLinkLauncher once implemented.
final class _StubExternalLinkLauncher implements ExternalLinkLauncher {
  const _StubExternalLinkLauncher();

  @override
  Future<ExternalLinkResult> launch(Uri url) async =>
      const ExternalLinkFailure('not implemented');
}

class MainApp extends StatelessWidget {
  const MainApp({
    super.key,
    required this.programRepo,
    required this.sessionRepo,
  });

  final ProgramRepository programRepo;
  final SessionRepository sessionRepo;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProgramRepository>.value(value: programRepo),
        RepositoryProvider<SessionRepository>.value(value: sessionRepo),
        RepositoryProvider<ExternalLinkLauncher>(
          create: (_) => const _StubExternalLinkLauncher(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        onGenerateRoute: ProgramManagementRouter.onGenerateRoute,
        initialRoute: ProgramManagementRoutes.programList,
      ),
    );
  }
}
