import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_progress/bloc/exercise_progress/bloc.dart';
import 'package:zamaj/modules/exercise_progress/models/exercise_progress_args.dart';
import 'package:zamaj/modules/exercise_progress/navigation/exercise_progress_routes.dart';
import 'package:zamaj/modules/exercise_progress/screens/exercise_progress_screen.dart';

abstract final class ExerciseProgressRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      ExerciseProgressRoutes.progress => _progressRoute(settings),
      _ => null,
    };
  }

  static Route<dynamic> _progressRoute(RouteSettings settings) {
    final args = settings.arguments! as ExerciseProgressArgs;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => BlocProvider(
        create: (_) => ExerciseProgressBloc(
          args: args,
          sessionRepository: context.read<SessionRepository>(),
        )..add(const ExerciseProgressLoadRequested()),
        child: ExerciseProgressScreen(displayName: args.displayName),
      ),
    );
  }
}
