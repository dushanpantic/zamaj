import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_router.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/bloc.dart';
import 'package:zamaj/modules/workout_day_picker/models/workout_day_picker_args.dart';
import 'package:zamaj/modules/workout_day_picker/navigation/workout_day_picker_routes.dart';
import 'package:zamaj/modules/workout_day_picker/screens/workout_day_picker_screen.dart';
import 'package:zamaj/navigation/session_active_placeholder_screen.dart';
import 'package:zamaj/navigation/session_routes.dart';

abstract final class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      WorkoutDayPickerRoutes.picker => _pickerRoute(settings),
      SessionRoutes.active => _sessionActiveRoute(settings),
      _ => ProgramManagementRouter.onGenerateRoute(settings),
    };
  }

  static Route<dynamic> _pickerRoute(RouteSettings settings) {
    final args = settings.arguments! as WorkoutDayPickerArgs;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => BlocProvider(
        create: (_) => WorkoutDayPickerBloc(
          programRepository: context.read<ProgramRepository>(),
          sessionRepository: context.read<SessionRepository>(),
          sessionFlowEngine: context.read<SessionFlowEngine>(),
          clock: context.read<Clock>(),
        )..add(WorkoutDayPickerOpened(args.programId)),
        child: const WorkoutDayPickerScreen(),
      ),
    );
  }

  static Route<dynamic> _sessionActiveRoute(RouteSettings settings) {
    final sessionId = settings.arguments! as String;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => SessionActivePlaceholderScreen(sessionId: sessionId),
    );
  }
}
