// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_parse_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanParseError _$PlanParseErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_PlanParseError', json, ($checkedConvert) {
      final val = _PlanParseError(
        line: $checkedConvert('line', (v) => (v as num).toInt()),
        column: $checkedConvert('column', (v) => (v as num).toInt()),
        code: $checkedConvert(
          'code',
          (v) => $enumDecode(_$PlanParseErrorCodeEnumMap, v),
        ),
        message: $checkedConvert('message', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PlanParseErrorToJson(_PlanParseError instance) =>
    <String, dynamic>{
      'line': instance.line,
      'column': instance.column,
      'code': _$PlanParseErrorCodeEnumMap[instance.code]!,
      'message': instance.message,
    };

const _$PlanParseErrorCodeEnumMap = {
  PlanParseErrorCode.emptyInput: 'empty_input',
  PlanParseErrorCode.unknownLine: 'unknown_line',
  PlanParseErrorCode.missingProgramName: 'missing_program_name',
  PlanParseErrorCode.missingWorkoutDay: 'missing_workout_day',
  PlanParseErrorCode.orphanSetLine: 'orphan_set_line',
  PlanParseErrorCode.orphanSupersetMarker: 'orphan_superset_marker',
  PlanParseErrorCode.inputTooLarge: 'input_too_large',
};
