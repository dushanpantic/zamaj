import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_error.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

part 'parse_result.freezed.dart';

@freezed
sealed class ParseResult with _$ParseResult {
  const factory ParseResult.success({
    required PlanDraft draft,
    required List<PlanParseWarning> warnings,
  }) = PlanParseSuccess;

  const factory ParseResult.failure(PlanParseError error) = PlanParseFailure;
}
