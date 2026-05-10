import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/program_management/services/text_plan/parse_result.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

import 'plan_import_event.dart';
import 'plan_import_state.dart';

class PlanImportBloc extends Bloc<PlanImportEvent, PlanImportState> {
  PlanImportBloc() : super(const PlanImportIdle(text: '')) {
    on<PlanImportTextChanged>(_onTextChanged);
    on<PlanImportParseRequested>(_onParseRequested);
  }

  void _onTextChanged(
    PlanImportTextChanged event,
    Emitter<PlanImportState> emit,
  ) {
    emit(PlanImportIdle(text: event.text));
  }

  Future<void> _onParseRequested(
    PlanImportParseRequested event,
    Emitter<PlanImportState> emit,
  ) async {
    final currentText = state.text;
    emit(PlanImportParsing(text: currentText));

    final result = TextPlanParser.parse(currentText);

    switch (result) {
      case PlanParseSuccess(:final draft, :final warnings):
        emit(
          PlanImportSuccess(
            text: currentText,
            draft: draft,
            warnings: warnings,
          ),
        );
      case PlanParseFailure(:final error):
        emit(PlanImportFailure(text: currentText, error: error));
    }
  }
}
