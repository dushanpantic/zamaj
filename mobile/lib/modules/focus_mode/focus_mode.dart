/// Focus-mode module.
///
/// Owns the execution screen (`SessionRoutes.focus`): single-exercise or
/// superset-group workout engine view that edits actual values with bump
/// buttons / numeric entry / time-based stopwatch, completes sets, and runs
/// the inline rest timer.
library;

export 'bloc/bloc.dart';
export 'models/focus_mode_args.dart';
export 'models/focus_mode_view_model.dart';
export 'models/rest_timer_view_model.dart';
export 'models/stopwatch_view_model.dart';
export 'models/undoable_set.dart';
export 'screens/focus_mode_screen.dart';
export 'services/focus_mode_assembler.dart';
export 'services/increment_rules.dart';
