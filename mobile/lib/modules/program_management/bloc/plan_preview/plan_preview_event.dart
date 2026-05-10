import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

sealed class PlanPreviewEvent extends Equatable {
  const PlanPreviewEvent();
}

final class PlanPreviewOpened extends PlanPreviewEvent {
  const PlanPreviewOpened({required this.planDraft, required this.warnings});

  final PlanDraft planDraft;
  final List<PlanParseWarning> warnings;

  @override
  List<Object?> get props => [planDraft, warnings];
}

final class PlanPreviewSavePressed extends PlanPreviewEvent {
  const PlanPreviewSavePressed();

  @override
  List<Object?> get props => [];
}

final class PlanPreviewDiscardPressed extends PlanPreviewEvent {
  const PlanPreviewDiscardPressed();

  @override
  List<Object?> get props => [];
}
