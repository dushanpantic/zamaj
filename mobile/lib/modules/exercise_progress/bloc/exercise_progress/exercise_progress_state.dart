import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class ExerciseProgressState extends Equatable {
  const ExerciseProgressState();

  @override
  List<Object?> get props => const [];
}

/// The series is being read and computed.
final class ExerciseProgressLoading extends ExerciseProgressState {
  const ExerciseProgressLoading();
}

/// Two or more top-set points — render the trend line.
final class ExerciseProgressTrend extends ExerciseProgressState {
  const ExerciseProgressTrend(this.series);

  final ExerciseProgressSeries series;

  @override
  List<Object?> get props => [series];
}

/// Exactly one logged session — render the single top-set stat, no trend line.
final class ExerciseProgressSingle extends ExerciseProgressState {
  const ExerciseProgressSingle(this.point);

  final ProgressPoint point;

  @override
  List<Object?> get props => [point];
}

/// Linked, weighted exercise with no completed sessions yet.
final class ExerciseProgressEmptyNoSessions extends ExerciseProgressState {
  const ExerciseProgressEmptyNoSessions();
}

/// A linked exercise whose measurement type isn't `repBased` — v1 tracks
/// weighted exercises only.
final class ExerciseProgressUnsupportedType extends ExerciseProgressState {
  const ExerciseProgressUnsupportedType();
}

/// The exercise has no Library link, so its history can't be tracked across
/// sessions.
final class ExerciseProgressUnlinked extends ExerciseProgressState {
  const ExerciseProgressUnlinked();
}

/// The completed-sessions read failed; the screen offers a retry.
final class ExerciseProgressError extends ExerciseProgressState {
  const ExerciseProgressError();
}
