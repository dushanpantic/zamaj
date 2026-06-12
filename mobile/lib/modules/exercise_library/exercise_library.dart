/// Exercise library module barrel.
///
/// Surfaces the public types other modules need (router, routes, args, picker
/// sheet, suggester service) without exposing bloc internals.
library;

// LinkSuggester and its cluster model now live in domain; re-export them so
// existing consumers of this barrel keep their import path.
export 'package:zamaj/modules/domain/models/link_suggestion_cluster.dart';
export 'package:zamaj/modules/domain/services/link_suggester.dart';
export 'models/exercise_library_args.dart';
export 'navigation/exercise_library_router.dart';
export 'navigation/exercise_library_routes.dart';
export 'widgets/library_picker_sheet.dart';
export 'widgets/measurement_type_chip.dart';
