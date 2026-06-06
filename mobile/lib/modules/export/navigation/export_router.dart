import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/bloc.dart';
import 'package:zamaj/modules/export/models/recent_sessions_args.dart';
import 'package:zamaj/modules/export/models/session_detail_args.dart';
import 'package:zamaj/modules/export/navigation/export_routes.dart';
import 'package:zamaj/modules/export/screens/recent_sessions_screen.dart';
import 'package:zamaj/modules/export/screens/session_detail_screen.dart';

abstract final class ExportRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      ExportRoutes.recentSessions => _recentSessionsRoute(settings),
      ExportRoutes.sessionDetail => _sessionDetailRoute(settings),
      _ => null,
    };
  }

  static Route<dynamic> _recentSessionsRoute(RouteSettings settings) {
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

  static Route<dynamic> _sessionDetailRoute(RouteSettings settings) {
    final args = settings.arguments! as SessionDetailArgs;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => BlocProvider(
        create: (_) => SessionDetailBloc(
          session: args.session,
          sessionRepository: context.read<SessionRepository>(),
          engine: context.read<SessionFlowEngine>(),
          clock: context.read<Clock>(),
        ),
        child: const SessionDetailScreen(),
      ),
    );
  }
}
