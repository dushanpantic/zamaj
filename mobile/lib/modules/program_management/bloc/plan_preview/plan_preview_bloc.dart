import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/clock.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/aggregate_saver.dart';
import 'package:zamaj/modules/program_management/services/plan_draft_to_aggregate.dart';

import 'plan_preview_event.dart';
import 'plan_preview_state.dart';

class PlanPreviewBloc extends Bloc<PlanPreviewEvent, PlanPreviewState> {
  PlanPreviewBloc({required AggregateSaver aggregateSaver})
    : _aggregateSaver = aggregateSaver,
      super(const PlanPreviewInitial()) {
    on<PlanPreviewOpened>(_onOpened);
    on<PlanPreviewSavePressed>(_onSavePressed);
    on<PlanPreviewDiscardPressed>(_onDiscardPressed);
  }

  final AggregateSaver _aggregateSaver;

  void _onOpened(PlanPreviewOpened event, Emitter<PlanPreviewState> emit) {
    final draft = PlanDraftToAggregate.convert(
      event.planDraft,
      idGenerator: const Uuid(),
      clock: const AppClock(),
    );
    emit(PlanPreviewPreviewing(draft: draft, warnings: event.warnings));
  }

  Future<void> _onSavePressed(
    PlanPreviewSavePressed event,
    Emitter<PlanPreviewState> emit,
  ) async {
    final current = state;
    if (current is! PlanPreviewPreviewing) return;

    emit(PlanPreviewSaving(draft: current.draft, warnings: current.warnings));

    try {
      final program = await _aggregateSaver.save(current.draft);
      emit(PlanPreviewSaved(programId: program.id));
    } on DomainError catch (e) {
      emit(
        PlanPreviewPreviewing(
          draft: current.draft,
          warnings: current.warnings,
          lastSaveError: e,
        ),
      );
    }
  }

  void _onDiscardPressed(
    PlanPreviewDiscardPressed event,
    Emitter<PlanPreviewState> emit,
  ) {
    emit(const PlanPreviewDiscarded());
  }
}
