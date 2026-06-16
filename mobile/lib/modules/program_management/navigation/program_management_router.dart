import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/plan_import/plan_import_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/screens/exercise_editor_screen.dart';
import 'package:zamaj/modules/program_management/screens/plan_import_screen.dart';
import 'package:zamaj/modules/program_management/screens/plan_preview_screen.dart';
import 'package:zamaj/modules/program_management/screens/program_editor_screen.dart';
import 'package:zamaj/modules/program_management/screens/workout_day_editor_screen.dart';
import 'package:zamaj/modules/program_management/services/aggregate_saver.dart';

abstract final class ProgramManagementRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      ProgramManagementRoutes.programEditor => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final args = settings.arguments as ProgramEditorArgs?;
          return BlocProvider(
            create: (_) => ProgramEditorBloc(
              programRepository: context.read<ProgramRepository>(),
              aggregateSaver: AggregateSaver(context.read<ProgramRepository>()),
            ),
            child: ProgramEditorScreen(args: args ?? const ProgramEditorArgs()),
          );
        },
      ),
      ProgramManagementRoutes.workoutDay => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final args = settings.arguments! as WorkoutDayArgs;
          return BlocProvider(
            create: (_) => WorkoutDayEditorBloc(
              programRepository: context.read<ProgramRepository>(),
              sessionRepository: context.read<SessionRepository>(),
            ),
            child: WorkoutDayEditorScreen(args: args),
          );
        },
      ),
      ProgramManagementRoutes.exercise => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final args = settings.arguments! as ExerciseArgs;
          return BlocProvider(
            create: (_) => ExerciseEditorBloc(
              programRepository: context.read<ProgramRepository>(),
              sessionRepository: context.read<SessionRepository>(),
              externalLinkLauncher: context.read<ExternalLinkLauncher>(),
            ),
            child: ExerciseEditorScreen(args: args),
          );
        },
      ),
      ProgramManagementRoutes.planImport => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => BlocProvider(
          create: (_) => PlanImportBloc(),
          child: const PlanImportScreen(),
        ),
      ),
      ProgramManagementRoutes.planPreview => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) {
          final args = settings.arguments! as PlanPreviewArgs;
          return BlocProvider(
            create: (_) => PlanPreviewBloc(
              aggregateSaver: AggregateSaver(context.read<ProgramRepository>()),
            ),
            child: PlanPreviewScreen(args: args),
          );
        },
      ),
      _ => null,
    };
  }
}
