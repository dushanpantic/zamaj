import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

sealed class PlanPreviewState extends Equatable {
  const PlanPreviewState();
}

final class PlanPreviewInitial extends PlanPreviewState {
  const PlanPreviewInitial();

  @override
  List<Object?> get props => [];
}

final class PlanPreviewPreviewing extends PlanPreviewState {
  const PlanPreviewPreviewing({
    required this.draft,
    required this.warnings,
    this.lastSaveError,
  });

  final ProgramDraft draft;
  final List<PlanParseWarning> warnings;
  final DomainError? lastSaveError;

  @override
  List<Object?> get props => [draft, warnings, lastSaveError];
}

final class PlanPreviewSaving extends PlanPreviewState {
  const PlanPreviewSaving({required this.draft, required this.warnings});

  final ProgramDraft draft;
  final List<PlanParseWarning> warnings;

  @override
  List<Object?> get props => [draft, warnings];
}

final class PlanPreviewSaved extends PlanPreviewState {
  const PlanPreviewSaved({required this.programId});

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class PlanPreviewDiscarded extends PlanPreviewState {
  const PlanPreviewDiscarded();

  @override
  List<Object?> get props => [];
}
