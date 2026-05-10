import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_parse_warning.freezed.dart';
part 'plan_parse_warning.g.dart';

enum PlanParseWarningCode {
  @JsonValue('invalid_rest_token')
  invalidRestToken,
  @JsonValue('unrecognized_trailing_token')
  unrecognizedTrailingToken,
}

@freezed
abstract class PlanParseWarning with _$PlanParseWarning {
  const factory PlanParseWarning({
    required int line,
    required int column,
    required PlanParseWarningCode code,
    required String offendingToken,
    required String exerciseDraftId,
  }) = _PlanParseWarning;

  factory PlanParseWarning.fromJson(Map<String, dynamic> json) =>
      _$PlanParseWarningFromJson(json);
}
