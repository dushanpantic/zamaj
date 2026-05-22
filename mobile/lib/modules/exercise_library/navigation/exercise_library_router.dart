import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/bloc/exercise_library_editor/bloc.dart';
import 'package:zamaj/modules/exercise_library/bloc/exercise_library_list/bloc.dart';
import 'package:zamaj/modules/exercise_library/bloc/link_suggestion/bloc.dart';
import 'package:zamaj/modules/exercise_library/models/exercise_library_args.dart';
import 'package:zamaj/modules/exercise_library/navigation/exercise_library_routes.dart';
import 'package:zamaj/modules/exercise_library/screens/exercise_library_editor_screen.dart';
import 'package:zamaj/modules/exercise_library/screens/exercise_library_list_screen.dart';
import 'package:zamaj/modules/exercise_library/screens/link_suggestion_screen.dart';

abstract final class ExerciseLibraryRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      ExerciseLibraryRoutes.list => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => BlocProvider(
          create: (_) => ExerciseLibraryListBloc(
            exerciseLibraryRepository: context
                .read<ExerciseLibraryRepository>(),
          ),
          child: const ExerciseLibraryListScreen(),
        ),
      ),
      ExerciseLibraryRoutes.editor => MaterialPageRoute<LibraryExercise>(
        settings: settings,
        builder: (context) {
          final args = settings.arguments as ExerciseLibraryEditorArgs?;
          return BlocProvider(
            create: (_) => ExerciseLibraryEditorBloc(
              exerciseLibraryRepository: context
                  .read<ExerciseLibraryRepository>(),
            ),
            child: ExerciseLibraryEditorScreen(
              args: args ?? const ExerciseLibraryEditorArgs(),
            ),
          );
        },
      ),
      ExerciseLibraryRoutes.linkSuggestions => MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => BlocProvider(
          create: (_) => LinkSuggestionBloc(
            programRepository: context.read<ProgramRepository>(),
            exerciseLibraryRepository: context
                .read<ExerciseLibraryRepository>(),
          ),
          child: const LinkSuggestionScreen(),
        ),
      ),
      _ => null,
    };
  }
}
