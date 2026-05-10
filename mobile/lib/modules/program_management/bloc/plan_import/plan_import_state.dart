import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_error.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

sealed class PlanImportState extends Equatable {
  const PlanImportState({required this.text});

  final String text;
}

final class PlanImportIdle extends PlanImportState {
  const PlanImportIdle({required super.text});

  @override
  List<Object?> get props => [text];
}

final class PlanImportParsing extends PlanImportState {
  const PlanImportParsing({required super.text});

  @override
  List<Object?> get props => [text];
}

final class PlanImportFailure extends PlanImportState {
  const PlanImportFailure({required super.text, required this.error});

  final PlanParseError error;

  @override
  List<Object?> get props => [text, error];
}

final class PlanImportSuccess extends PlanImportState {
  const PlanImportSuccess({
    required super.text,
    required this.draft,
    required this.warnings,
  });

  final PlanDraft draft;
  final List<PlanParseWarning> warnings;

  @override
  List<Object?> get props => [text, draft, warnings];
}
