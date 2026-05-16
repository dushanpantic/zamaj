import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/bloc.dart';
import 'package:zamaj/modules/export/models/recent_sessions_args.dart';
import 'package:zamaj/modules/export/navigation/export_routes.dart';
import 'package:zamaj/modules/export/screens/recent_sessions_screen.dart';

abstract final class ExportRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name != ExportRoutes.recentSessions) return null;
    final args = settings.arguments! as RecentSessionsArgs;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => BlocProvider(
        create: (_) => RecentSessionsBloc(
          programRepository: context.read<ProgramRepository>(),
          sessionRepository: context.read<SessionRepository>(),
          clock: context.read<Clock>(),
        )..add(RecentSessionsOpened(args.programId)),
        child: const RecentSessionsScreen(),
      ),
    );
  }
}
