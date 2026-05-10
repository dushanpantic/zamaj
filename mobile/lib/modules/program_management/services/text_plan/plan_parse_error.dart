import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_parse_error.freezed.dart';
part 'plan_parse_error.g.dart';

enum PlanParseErrorCode {
  @JsonValue('empty_input')
  emptyInput,
  @JsonValue('unknown_line')
  unknownLine,
  @JsonValue('missing_program_name')
  missingProgramName,
  @JsonValue('missing_workout_day')
  missingWorkoutDay,
  @JsonValue('orphan_set_line')
  orphanSetLine,
  @JsonValue('orphan_superset_marker')
  orphanSupersetMarker,
  @JsonValue('input_too_large')
  inputTooLarge,
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
