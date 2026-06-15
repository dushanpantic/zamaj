import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_progress/bloc/exercise_progress/exercise_progress_event.dart';
import 'package:zamaj/modules/exercise_progress/bloc/exercise_progress/exercise_progress_state.dart';
import 'package:zamaj/modules/exercise_progress/models/exercise_progress_args.dart';

/// Drives the exercise-progress screen.
///
/// Gates on the exercise before reading: a null `libraryExerciseId` is
/// [ExerciseProgressUnlinked] and a non-`repBased` type is
/// [ExerciseProgressUnsupportedType] — neither touches the repository. For a
/// linked, weighted exercise it reads every completed session and runs
/// [ExerciseProgressAggregator], mapping 0 / 1 / ≥2 points to
/// empty / single / trend. The read is recomputed from live data on every load
/// (so a deleted session drops out) and wrapped in try/catch so a failure
/// surfaces a retry-able [ExerciseProgressError].
class ExerciseProgressBloc
    extends Bloc<ExerciseProgressEvent, ExerciseProgressState> {
  ExerciseProgressBloc({
    required ExerciseProgressArgs args,
    required SessionRepository sessionRepository,
  }) : _args = args,
       _sessionRepository = sessionRepository,
       super(const ExerciseProgressLoading()) {
    on<ExerciseProgressLoadRequested>(_onLoadRequested);
  }

  final ExerciseProgressArgs _args;
  final SessionRepository _sessionRepository;

  Future<void> _onLoadRequested(
    ExerciseProgressLoadRequested event,
    Emitter<ExerciseProgressState> emit,
  ) async {
    final libraryExerciseId = _args.libraryExerciseId;
    if (libraryExerciseId == null) {
      emit(const ExerciseProgressUnlinked());
      return;
    }
    if (_args.measurementType is! RepBasedMeasurement) {
      emit(const ExerciseProgressUnsupportedType());
      return;
    }

    emit(const ExerciseProgressLoading());

    final List<Session> sessions;
    try {
      sessions = await _sessionRepository.listCompletedSessions();
    } catch (_) {
      emit(const ExerciseProgressError());
      return;
    }

    final series = ExerciseProgressAggregator.compute(
      libraryExerciseId: libraryExerciseId,
      sessions: sessions,
    );

    if (series.isEmpty) {
      emit(const ExerciseProgressEmptyNoSessions());
    } else if (series.isSingle) {
      emit(ExerciseProgressSingle(series.points.single));
    } else {
      emit(ExerciseProgressTrend(series));
    }
  }
}
