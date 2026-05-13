/// Workout-overview module.
///
/// Owns the editable session workspace screen (`SessionRoutes.active`):
/// inline expansion, manual logging, replacement, reorder, drag-to-superset,
/// session notes, extra work, and session end.
library;

export 'bloc/bloc.dart';
export 'models/drop_intent.dart';
export 'models/exercise_view_model.dart';
export 'models/set_row_view_model.dart';
export 'models/superset_group_view_model.dart';
export 'models/workout_overview_args.dart';
export 'screens/workout_overview_screen.dart';
export 'services/drop_resolver.dart';
export 'services/exercise_view_model_assembler.dart';
export 'services/planned_summary_formatter.dart';
