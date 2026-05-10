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
  PlanParseErrorCode.empty_input: 'empty_input',
  PlanParseErrorCode.unknown_line: 'unknown_line',
  PlanParseErrorCode.missing_program_name: 'missing_program_name',
  PlanParseErrorCode.missing_workout_day: 'missing_workout_day',
  PlanParseErrorCode.orphan_set_line: 'orphan_set_line',
  PlanParseErrorCode.orphan_superset_marker: 'orphan_superset_marker',
  PlanParseErrorCode.input_too_large: 'input_too_large',
};
