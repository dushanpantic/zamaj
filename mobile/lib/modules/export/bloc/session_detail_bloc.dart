import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/session_detail_event.dart';
import 'package:zamaj/modules/export/bloc/session_detail_state.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

/// Drives the post-session review screen.
///
/// Reads reactively via [SessionRepository.watchSession] so a corrected value
/// re-renders with no manual refresh, and writes via
/// [SessionFlowEngine.updateExecutedSet]. This is a review surface, not session
/// flow, so it reads through the repository contract while still routing the
/// mutation through the engine. Whether editing is allowed is decided once at
/// open (in-week + ended) and held stable for the screen's lifetime.
class SessionDetailBloc extends Bloc<SessionDetailEvent, SessionDetailState> {
  SessionDetailBloc({
    required Session session,
    required SessionRepository sessionRepository,
    required SessionFlowEngine engine,
    required Clock clock,
  }) : _repository = sessionRepository,
       _engine = engine,
       super(
         SessionDetailLoaded(
           session: session,
           groups: ExerciseViewModelAssembler.assembleReadOnly(session),
           canEdit: SessionEditability.canEditValues(
             session,
             TrainingWeek.compute(clock.now()),
           ),
         ),
       ) {
    on<SessionDetailSetValueEdited>(_onSetValueEdited);
    on<SessionDetailSessionUpdated>(_onSessionUpdated);
    _subscribe(session.id);
  }

  final SessionRepository _repository;
  final SessionFlowEngine _engine;
  StreamSubscription<Session?>? _subscription;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  void _subscribe(String sessionId) {
    _subscription = _repository.watchSession(sessionId).listen((session) {
      // A null emission means the session was deleted elsewhere; keep the last
      // rendered snapshot rather than blanking a review the user is reading.
      if (session != null) {
        add(SessionDetailSessionUpdated(session));
      }
    });
  }

  void _onSessionUpdated(
    SessionDetailSessionUpdated event,
    Emitter<SessionDetailState> emit,
  ) {
    final current = state;
    if (current is! SessionDetailLoaded) return;
    emit(
      SessionDetailLoaded(
        session: event.session,
        groups: ExerciseViewModelAssembler.assembleReadOnly(event.session),
        // canEdit is fixed for the screen's lifetime; never recomputed mid-view.
        canEdit: current.canEdit,
      ),
    );
  }

  Future<void> _onSetValueEdited(
    SessionDetailSetValueEdited event,
    Emitter<SessionDetailState> emit,
  ) async {
    try {
      // The returned SessionState is discarded — the watch stream re-emits the
      // fresh Session, which drives the re-render.
      await _engine.updateExecutedSet(
        executedSetId: event.executedSetId,
        actualValues: event.actualValues,
      );
    } on DomainError {
      // The review screen has no edit-error surface; keep the prior render.
    }
  }
}
