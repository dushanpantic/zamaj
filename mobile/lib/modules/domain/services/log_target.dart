import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_target.freezed.dart';

/// A loggable slot on a single [SessionExercise].
///
/// Pure projection over a [Session]: one [LogTarget] per in-progress exercise,
/// each pointing at the next chronological set slot the user could log
/// (`plannedSetIndex == executedSets.length`). Never persisted.
@freezed
abstract class LogTarget with _$LogTarget {
  const factory LogTarget({
    required String sessionExerciseId,
    required int plannedSetIndex,
  }) = _LogTarget;
}
