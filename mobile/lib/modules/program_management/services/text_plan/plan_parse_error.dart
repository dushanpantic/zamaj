import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_parse_error.freezed.dart';
part 'plan_parse_error.g.dart';

enum PlanParseErrorCode {
  empty_input,
  unknown_line,
  missing_program_name,
  missing_workout_day,
  orphan_set_line,
  orphan_superset_marker,
  input_too_large,
}

@freezed
abstract class PlanParseError with _$PlanParseError {
  const factory PlanParseError({
    required int line,
    required int column,
    required PlanParseErrorCode code,
    required String message,
  }) = _PlanParseError;

  factory PlanParseError.fromJson(Map<String, dynamic> json) =>
      _$PlanParseErrorFromJson(json);
}
