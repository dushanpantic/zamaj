import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

abstract final class ProgramManagementRoutes {
  static const programEditor = '/programs/editor';
  static const workoutDay = '/programs/workout-day';
  static const exercise = '/programs/exercise';
  static const planImport = '/programs/import';
  static const planPreview = '/programs/import/preview';
}

class ProgramEditorArgs {
  const ProgramEditorArgs({this.programId});

  final String? programId;
}

class WorkoutDayArgs {
  const WorkoutDayArgs({required this.workoutDayId});

  final String workoutDayId;
}

class ExerciseArgs {
  const ExerciseArgs({required this.exerciseId});

  final String exerciseId;
}

class PlanPreviewArgs {
  const PlanPreviewArgs({required this.draft, required this.warnings});

  final PlanDraft draft;
  final List<PlanParseWarning> warnings;
}
